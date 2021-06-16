# frozen_string_literal: true

# TodoService class
#
# Used for creating/updating todos after certain user actions
#
# Ex.
#   TodoService.new.new_issue(issue, current_user)
#
class TodoService
  include Gitlab::Utils::UsageData
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
    resolve_todos_for_target(issue, current_user)
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
    todo_user_ids = target.todos.distinct_user_ids

    yield target

    Users::UpdateTodoCountCacheService.new(todo_user_ids).execute if todo_user_ids.present?
  end

  # When we reassign an assignable object (issuable, alert) we should:
  #
  #  * create a pending todo for new assignee if object is assigned
  #
  def reassigned_assignable(issuable, current_user, old_assignees = [])
    create_assignment_todo(issuable, current_user, old_assignees)
  end

  # When we reassign an reviewable object (merge request) we should:
  #
  #  * create a pending todo for new reviewer if object is assigned
  #
  def reassigned_reviewable(issuable, current_user, old_reviewers = [])
    create_reviewer_todo(issuable, current_user, old_reviewers)
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
    resolve_todos_for_target(merge_request, current_user)
  end

  # When merge a merge request we should:
  #
  #  * mark all pending todos related to the target for the current user as done
  #
  def merge_merge_request(merge_request, current_user)
    resolve_todos_for_target(merge_request, current_user)
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
    resolve_todos_for_target(merge_request, current_user)
  end

  # When a build is retried to a merge request we should:
  #
  #  * mark all pending todos related to the merge request as done for each merge participant
  #
  def merge_request_build_retried(merge_request)
    merge_request.merge_participants.each do |user|
      resolve_todos_for_target(merge_request, user)
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
    resolve_todos_for_target(awardable, current_user)
  end

  # When user marks a target as todo
  def mark_todo(target, current_user)
    attributes = attributes_for_todo(target.project, target, current_user, Todo::MARKED)
    create_todos(current_user, attributes)
  end

  def todo_exist?(issuable, current_user)
    TodosFinder.new(current_user).any_for_target?(issuable, :pending)
  end

  # Resolves all todos related to target
  def resolve_todos_for_target(target, current_user)
    attributes = attributes_for_target(target)

    resolve_todos(pending_todos([current_user], attributes), current_user)
  end

  def resolve_todos(todos, current_user, resolution: :done, resolved_by_action: :system_done)
    todos_ids = todos.batch_update(state: resolution, resolved_by_action: resolved_by_action)

    current_user.update_todos_count_cache

    todos_ids
  end

  def resolve_todo(todo, current_user, resolution: :done, resolved_by_action: :system_done)
    return if todo.done?

    todo.update(state: resolution, resolved_by_action: resolved_by_action)

    current_user.update_todos_count_cache
  end

  def restore_todos(todos, current_user)
    todos_ids = todos.batch_update(state: :pending)

    current_user.update_todos_count_cache

    todos_ids
  end

  def restore_todo(todo, current_user)
    return if todo.pending?

    todo.update(state: :pending)

    current_user.update_todos_count_cache
  end

  def create_request_review_todo(target, author, reviewers)
    attributes = attributes_for_todo(target.project, target, author, Todo::REVIEW_REQUESTED)
    create_todos(reviewers, attributes)
  end

  private

  def create_todos(users, attributes)
    users = Array(users)

    return if users.empty?

    users_with_pending_todos = pending_todos(users, attributes).distinct_user_ids
    users.reject! { |user| users_with_pending_todos.include?(user.id) && Feature.disabled?(:multiple_todos, user) }

    todos = users.map do |user|
      issue_type = attributes.delete(:issue_type)
      track_todo_creation(user, issue_type)

      Todo.create(attributes.merge(user_id: user.id))
    end

    Users::UpdateTodoCountCacheService.new(users.map(&:id)).execute

    todos
  end

  def new_issuable(issuable, author)
    create_assignment_todo(issuable, author)
    create_reviewer_todo(issuable, author) if issuable.allows_reviewers?
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
    target = note.noteable

    resolve_todos_for_target(target, author)
    create_mention_todos(project, target, author, note, skip_users)
  end

  def create_assignment_todo(target, author, old_assignees = [])
    if target.assignees.any?
      assignees = target.assignees - old_assignees
      attributes = attributes_for_todo(target.project, target, author, Todo::ASSIGNED)
      create_todos(assignees, attributes)
    end
  end

  def create_reviewer_todo(target, author, old_reviewers = [])
    if target.reviewers.any?
      reviewers = target.reviewers - old_reviewers
      create_request_review_todo(target, author, reviewers)
    end
  end

  def create_mention_todos(parent, target, author, note = nil, skip_users = [])
    # Create Todos for directly addressed users
    directly_addressed_users = filter_directly_addressed_users(parent, note || target, author, skip_users)
    attributes = attributes_for_todo(parent, target, author, Todo::DIRECTLY_ADDRESSED, note)
    create_todos(directly_addressed_users, attributes)

    # Create Todos for mentioned users
    mentioned_users = filter_mentioned_users(parent, note || target, author, skip_users + directly_addressed_users)
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
    elsif target.is_a?(Issue)
      attributes[:issue_type] = target.issue_type
    elsif target.is_a?(Discussion)
      attributes.merge!(target_type: nil, target_id: nil, discussion: target)
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

  def pending_todos(users, criteria = {})
    PendingTodosFinder.new(users, criteria).execute
  end

  def track_todo_creation(user, issue_type)
    return unless issue_type == 'incident'

    track_usage_event(:incident_management_incident_todo, user.id)
  end
end

TodoService.prepend_mod_with('TodoService')
