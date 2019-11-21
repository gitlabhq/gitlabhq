# frozen_string_literal: true

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
  def update_issue(issue, current_user, skip_users = [])
    update_issuable(issue, current_user, skip_users)
  end

  # When close an issue we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def close_issue(issue, current_user)
    mark_pending_todos_as_done(issue, current_user)
  end

  # When we destroy a todo target we should:
  #
  #  * refresh the todos count cache for all users with todos on the target
  #
  # This needs to yield back to the caller to destroy the target, because it
  # collects the todo users before the todos themselves are deleted, then
  # updates the todo counts for those users.
  #
  def destroy_target(target)
    todo_users = UsersWithPendingTodosFinder.new(target).execute.to_a

    yield target

    todo_users.each(&:update_todos_count_cache)
  end

  # When we reassign an issuable we should:
  #
  #  * create a pending todo for new assignee if issuable is assigned
  #
  def reassigned_issuable(issuable, current_user, old_assignees = [])
    create_assignment_todo(issuable, current_user, old_assignees)
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
  def update_merge_request(merge_request, current_user, skip_users = [])
    update_issuable(merge_request, current_user, skip_users)
  end

  # When close a merge request we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def close_merge_request(merge_request, current_user)
    mark_pending_todos_as_done(merge_request, current_user)
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
  #  * create a todo for each merge participant
  #
  def merge_request_build_failed(merge_request)
    merge_request.merge_participants.each do |user|
      create_build_failed_todo(merge_request, user)
    end
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
  #  * mark all pending todos related to the merge request as done for each merge participant
  #
  def merge_request_build_retried(merge_request)
    merge_request.merge_participants.each do |user|
      mark_pending_todos_as_done(merge_request, user)
    end
  end

  # When a merge request could not be merged due to its unmergeable state we should:
  #
  #  * create a todo for each merge participant
  #
  def merge_request_became_unmergeable(merge_request)
    merge_request.merge_participants.each do |user|
      create_unmergeable_todo(merge_request, user)
    end
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
  def update_note(note, current_user, skip_users = [])
    handle_note(note, current_user, skip_users)
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
    update_todos_state(todos, current_user, :done)
  end

  def mark_todos_as_done_by_ids(ids, current_user)
    todos = todos_by_ids(ids, current_user)
    mark_todos_as_done(todos, current_user)
  end

  def mark_all_todos_as_done_by_user(current_user)
    todos = TodosFinder.new(current_user).execute
    mark_todos_as_done(todos, current_user)
  end

  # When user marks some todos as pending
  def mark_todos_as_pending(todos, current_user)
    update_todos_state(todos, current_user, :pending)
  end

  def mark_todos_as_pending_by_ids(ids, current_user)
    todos = todos_by_ids(ids, current_user)
    mark_todos_as_pending(todos, current_user)
  end

  # When user marks an issue as todo
  def mark_todo(issuable, current_user)
    attributes = attributes_for_todo(issuable.project, issuable, current_user, Todo::MARKED)
    create_todos(current_user, attributes)
  end

  def todo_exist?(issuable, current_user)
    TodosFinder.new(current_user).any_for_target?(issuable, :pending)
  end

  private

  def todos_by_ids(ids, current_user)
    current_user.todos_limited_to(Array(ids))
  end

  def update_todos_state(todos, current_user, state)
    todos_ids = todos.update_state(state)

    current_user.update_todos_count_cache

    todos_ids
  end

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
    create_mention_todos(issuable.project, issuable, author)
  end

  def update_issuable(issuable, author, skip_users = [])
    # Skip toggling a task list item in a description
    return if toggling_tasks?(issuable)

    create_mention_todos(issuable.project, issuable, author, nil, skip_users)
  end

  def toggling_tasks?(issuable)
    issuable.previous_changes.include?('description') &&
      issuable.tasks? && issuable.updated_tasks.any?
  end

  def handle_note(note, author, skip_users = [])
    return unless note.can_create_todo?

    project = note.project
    target  = note.noteable

    mark_pending_todos_as_done(target, author)
    create_mention_todos(project, target, author, note, skip_users)
  end

  def create_assignment_todo(issuable, author, old_assignees = [])
    if issuable.assignees.any?
      assignees = issuable.assignees - old_assignees
      attributes = attributes_for_todo(issuable.project, issuable, author, Todo::ASSIGNED)
      create_todos(assignees, attributes)
    end
  end

  def create_mention_todos(parent, target, author, note = nil, skip_users = [])
    # Create Todos for directly addressed users
    directly_addressed_users = filter_directly_addressed_users(parent, note || target, author, skip_users)
    attributes = attributes_for_todo(parent, target, author, Todo::DIRECTLY_ADDRESSED, note)
    create_todos(directly_addressed_users, attributes)

    # Create Todos for mentioned users
    mentioned_users = filter_mentioned_users(parent, note || target, author, skip_users)
    attributes = attributes_for_todo(parent, target, author, Todo::MENTIONED, note)
    create_todos(mentioned_users, attributes)
  end

  def create_build_failed_todo(merge_request, todo_author)
    attributes = attributes_for_todo(merge_request.project, merge_request, todo_author, Todo::BUILD_FAILED)
    create_todos(todo_author, attributes)
  end

  def create_unmergeable_todo(merge_request, todo_author)
    attributes = attributes_for_todo(merge_request.project, merge_request, todo_author, Todo::UNMERGEABLE)
    create_todos(todo_author, attributes)
  end

  def attributes_for_target(target)
    attributes = {
      project_id: target&.project&.id,
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
      project_id: project&.id,
      author_id: author.id,
      action: action,
      note: note
    )
  end

  def filter_todo_users(users, parent, target)
    reject_users_without_access(users, parent, target).uniq
  end

  def filter_mentioned_users(parent, target, author, skip_users = [])
    mentioned_users = target.mentioned_users(author) - skip_users
    filter_todo_users(mentioned_users, parent, target)
  end

  def filter_directly_addressed_users(parent, target, author, skip_users = [])
    directly_addressed_users = target.directly_addressed_users(author) - skip_users
    filter_todo_users(directly_addressed_users, parent, target)
  end

  def reject_users_without_access(users, parent, target)
    target = target.noteable if target.is_a?(Note)

    if target.respond_to?(:to_ability_name)
      select_users(users, :"read_#{target.to_ability_name}", target)
    else
      select_users(users, :read_project, parent)
    end
  end

  def select_users(users, ability, subject)
    users.select do |user|
      user.can?(ability.to_sym, subject)
    end
  end

  def pending_todos(user, criteria = {})
    PendingTodosFinder.new(user, criteria).execute
  end
end

TodoService.prepend_if_ee('EE::TodoService')
