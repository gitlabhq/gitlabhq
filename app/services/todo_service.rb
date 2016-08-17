# TodoService class
#
# Used for creating/updating todos after certain user actions
#
# Ex.
#   TodoService.new.new_issue(issue, current_user)
#
class TodoService
  # When create an issue we should:
  #
  #  * create a todo for assignee if issue is assigned
  #  * create a todo for each mentioned user on issue
  #
  def new_issue(issue, current_user)
    new_issuable(issue, current_user)
  end

  # When update an issue we should:
  #
  #  * mark all pending todos related to the issue for the current user as done
  #
  def update_issue(issue, current_user)
    update_issuable(issue, current_user)
  end

  # When close an issue we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def close_issue(issue, current_user)
    mark_pending_todos_as_done(issue, current_user)
  end

  # When we reassign an issue we should:
  #
  #  * create a pending todo for new assignee if issue is assigned
  #
  def reassigned_issue(issue, current_user)
    create_assignment_todo(issue, current_user)
  end

  # When create a merge request we should:
  #
  #  * creates a pending todo for assignee if merge request is assigned
  #  * create a todo for each mentioned user on merge request
  #
  def new_merge_request(merge_request, current_user)
    new_issuable(merge_request, current_user)
  end

  # When update a merge request we should:
  #
  #  * create a todo for each mentioned user on merge request
  #
  def update_merge_request(merge_request, current_user)
    update_issuable(merge_request, current_user)
  end

  # When close a merge request we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def close_merge_request(merge_request, current_user)
    mark_pending_todos_as_done(merge_request, current_user)
  end

  # When we reassign a merge request we should:
  #
  #  * creates a pending todo for new assignee if merge request is assigned
  #
  def reassigned_merge_request(merge_request, current_user)
    create_assignment_todo(merge_request, current_user)
  end

  # When merge a merge request we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def merge_merge_request(merge_request, current_user)
    mark_pending_todos_as_done(merge_request, current_user)
  end

  # When a build fails on the HEAD of a merge request we should:
  #
  #  * create a todo for that user to fix it
  #
  def merge_request_build_failed(merge_request)
    create_build_failed_todo(merge_request)
  end

  # When new approvers are added for a merge request:
  #
  #  * create a todo for those users to approve the MR
  #
  def add_merge_request_approvers(merge_request, approvers)
    create_approval_required_todos(merge_request, approvers, merge_request.author)
  end

  # When a new commit is pushed to a merge request we should:
  #
  #  * mark all pending todos related to the merge request for that user as done
  #
  def merge_request_push(merge_request, current_user)
    mark_pending_todos_as_done(merge_request, current_user)
  end

  # When a build is retried to a merge request we should:
  #
  #  * mark all pending todos related to the merge request for the author as done
  #
  def merge_request_build_retried(merge_request)
    mark_pending_todos_as_done(merge_request, merge_request.author)
  end

  # When create a note we should:
  #
  #  * mark all pending todos related to the noteable for the note author as done
  #  * create a todo for each mentioned user on note
  #
  def new_note(note, current_user)
    handle_note(note, current_user)
  end

  # When update a note we should:
  #
  #  * mark all pending todos related to the noteable for the current user as done
  #  * create a todo for each new user mentioned on note
  #
  def update_note(note, current_user)
    handle_note(note, current_user)
  end

  # When an emoji is awarded we should:
  #
  #  * mark all pending todos related to the awardable for the current user as done
  #
  def new_award_emoji(awardable, current_user)
    mark_pending_todos_as_done(awardable, current_user)
  end

  # When marking pending todos as done we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def mark_pending_todos_as_done(target, user)
    attributes = attributes_for_target(target)
    pending_todos(user, attributes).update_all(state: :done)
    user.update_todos_count_cache
  end

  # When user marks some todos as done
  def mark_todos_as_done(todos, current_user)
    todos = current_user.todos.where(id: todos.map(&:id)) unless todos.respond_to?(:update_all)

    marked_todos = todos.update_all(state: :done)
    current_user.update_todos_count_cache
    marked_todos
  end

  # When user marks an issue as todo
  def mark_todo(issuable, current_user)
    attributes = attributes_for_todo(issuable.project, issuable, current_user, Todo::MARKED)
    create_todos(current_user, attributes)
  end

  private

  def create_todos(users, attributes)
    Array(users).map do |user|
      next if pending_todos(user, attributes).exists?
      todo = Todo.create(attributes.merge(user_id: user.id))
      user.update_todos_count_cache
      todo
    end
  end

  def new_issuable(issuable, author)
    create_assignment_todo(issuable, author)

    if issuable.is_a?(MergeRequest)
      create_approval_required_todos(issuable, issuable.overall_approvers, author)
    end

    create_mention_todos(issuable.project, issuable, author)
  end

  def update_issuable(issuable, author)
    # Skip toggling a task list item in a description
    return if toggling_tasks?(issuable)

    create_mention_todos(issuable.project, issuable, author)
  end

  def toggling_tasks?(issuable)
    issuable.previous_changes.include?('description') &&
      issuable.tasks? && issuable.updated_tasks.any?
  end

  def handle_note(note, author)
    # Skip system notes, and notes on project snippet
    return if note.system? || note.for_snippet?

    project = note.project
    target  = note.noteable

    mark_pending_todos_as_done(target, author)
    create_mention_todos(project, target, author, note)
  end

  def create_assignment_todo(issuable, author)
    if issuable.assignee
      attributes = attributes_for_todo(issuable.project, issuable, author, Todo::ASSIGNED)
      create_todos(issuable.assignee, attributes)
    end
  end

  def create_mention_todos(project, target, author, note = nil)
    mentioned_users = filter_mentioned_users(project, note || target, author)
    attributes = attributes_for_todo(project, target, author, Todo::MENTIONED, note)
    create_todos(mentioned_users, attributes)
  end

  def create_approval_required_todos(merge_request, approvers, author)
    attributes = attributes_for_todo(merge_request.project, merge_request, author, Todo::APPROVAL_REQUIRED)
    create_todos(approvers.map(&:user), attributes)
  end

  def create_build_failed_todo(merge_request)
    author = merge_request.author
    attributes = attributes_for_todo(merge_request.project, merge_request, author, Todo::BUILD_FAILED)
    create_todos(author, attributes)
  end

  def attributes_for_target(target)
    attributes = {
      project_id: target.project.id,
      target_id: target.id,
      target_type: target.class.name,
      commit_id: nil
    }

    if target.is_a?(Commit)
      attributes.merge!(target_id: nil, commit_id: target.id)
    end

    attributes
  end

  def attributes_for_todo(project, target, author, action, note = nil)
    attributes_for_target(target).merge!(
      project_id: project.id,
      author_id: author.id,
      action: action,
      note: note
    )
  end

  def filter_mentioned_users(project, target, author)
    mentioned_users = target.mentioned_users(author)
    mentioned_users = reject_users_without_access(mentioned_users, project, target)
    mentioned_users.uniq
  end

  def reject_users_without_access(users, project, target)
    if target.is_a?(Note) && target.for_issue?
      target = target.noteable
    end

    if target.is_a?(Issue)
      select_users(users, :read_issue, target)
    else
      select_users(users, :read_project, project)
    end
  end

  def select_users(users, ability, subject)
    users.select do |user|
      user.can?(ability.to_sym, subject)
    end
  end

  def pending_todos(user, criteria = {})
    valid_keys = [:project_id, :target_id, :target_type, :commit_id]
    user.todos.pending.where(criteria.slice(*valid_keys))
  end
end
