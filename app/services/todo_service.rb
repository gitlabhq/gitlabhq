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

  BATCH_SIZE = 100

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

  # When a SSH key is expiring soon we should:
  #
  # * create a todo for the user owning that SSH key
  #
  def ssh_key_expiring_soon(ssh_keys)
    create_ssh_key_todos(Array(ssh_keys), ::Todo::SSH_KEY_EXPIRING_SOON)
  end

  # When a SSH key expired we should:
  #
  # * resolve any corresponding "expiring soon" todo
  # * create a todo for the user owning that SSH key
  #
  def ssh_key_expired(ssh_keys)
    ssh_keys = Array(ssh_keys)

    # Resolve any pending "expiring soon" todos for these keys
    expiring_key_todos = ::Todo.pending_for_expiring_ssh_keys(ssh_keys.map(&:id))
    expiring_key_todos.batch_update(state: :done, resolved_by_action: :system_done)

    create_ssh_key_todos(ssh_keys, ::Todo::SSH_KEY_EXPIRED)
  end

  # When a merge request receives a review
  #
  #   * Mark all outstanding todos on this MR for the current user as done
  #
  def new_review(review, current_user)
    resolve_todos_for_target(review.merge_request, current_user)
  end

  # When user marks a target as todo
  def mark_todo(target, current_user)
    project = target.project
    attributes = attributes_for_todo(project, target, current_user, Todo::MARKED)

    todos = create_todos(current_user, attributes, target_namespace(target), project)
    work_item_activity_counter.track_work_item_mark_todo_action(author: current_user) if target.is_a?(WorkItem)

    todos
  end

  def todo_exist?(issuable, current_user)
    TodosFinder.new(current_user).any_for_target?(issuable, :pending)
  end

  # Resolves all todos related to target for the current_user
  def resolve_todos_for_target(target, current_user)
    attributes = attributes_for_target(target)

    resolve_todos(pending_todos([current_user], attributes), current_user)

    GraphqlTriggers.issuable_todo_updated(target)
  end

  # Resolves all todos related to target for all users
  def resolve_todos_with_attributes_for_target(target, attributes, resolution: :done, resolved_by_action: :system_done)
    target_attributes = { target_id: target.id, target_type: target.class.polymorphic_name }
    attributes.merge!(target_attributes)
    attributes[:preload_user_association] = true

    todos = PendingTodosFinder.new(attributes).execute
    users = todos.map(&:user)
    todos_ids = todos.batch_update(state: resolution, resolved_by_action: resolved_by_action)
    users.each(&:update_todos_count_cache)
    todos_ids
  end

  def resolve_todos(todos, current_user, resolution: :done, resolved_by_action: :system_done)
    todos_ids = todos.batch_update(state: resolution, resolved_by_action: resolved_by_action, snoozed_until: nil)

    current_user.update_todos_count_cache

    todos_ids
  end

  def resolve_todo(todo, current_user, resolution: :done, resolved_by_action: :system_done)
    return if todo.done?

    todo.update(state: resolution, resolved_by_action: resolved_by_action, snoozed_until: nil)

    GraphqlTriggers.issuable_todo_updated(todo.target)

    current_user.update_todos_count_cache
  end

  def resolve_access_request_todos(member)
    return if member.nil?

    # Group or Project
    target = member.source

    todos_params = {
      state: :pending,
      author_id: member.user_id,
      action: ::Todo::MEMBER_ACCESS_REQUESTED,
      type: target.class.polymorphic_name
    }

    resolve_todos_with_attributes_for_target(target, todos_params)
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
    project = target.project
    attributes = attributes_for_todo(project, target, author, Todo::REVIEW_REQUESTED)
    create_todos(reviewers, attributes, project.namespace, project)
  end

  def create_member_access_request_todos(member)
    source = member.source
    attributes = attributes_for_access_request_todos(source, member.user, Todo::MEMBER_ACCESS_REQUESTED)

    approvers = source.access_request_approvers_to_be_notified.map(&:user)
    return true if approvers.empty?

    if source.instance_of? Project
      project = source
      namespace = project.namespace
    else
      project = nil
      namespace = source
    end

    create_todos(approvers, attributes, namespace, project)
  end

  private

  def create_todos(users, attributes, namespace, project)
    users = Array(users)

    return if users.empty?

    issue_type = attributes.delete(:issue_type)

    excluded_user_ids = excluded_user_ids(users, attributes)
    users.reject! { |user| excluded_user_ids.include?(user.id) }

    todos = bulk_insert_todos(users, attributes)
    users.each { |user| track_todo_creation(user, issue_type, namespace, project) }

    # replicate `keep_around_commit` after_save callback
    todos.select { |todo| todo.commit_id.present? }.each(&:keep_around_commit)

    Users::UpdateTodoCountCacheService.new(users.map(&:id)).execute

    todos
  end

  def excluded_user_ids(users, attributes)
    users_single_todos, users_multiple_todos = users.partition { |u| Feature.disabled?(:multiple_todos, u) }
    excluded_user_ids = []

    if users_single_todos.present?
      excluded_user_ids += pending_todos(
        users_single_todos,
        attributes.slice(:project_id, :target_id, :target_type, :commit_id, :discussion)
      ).distinct_user_ids
    end

    if users_multiple_todos.present? && Todo::ACTIONS_MULTIPLE_ALLOWED.exclude?(attributes.fetch(:action))
      excluded_user_ids += pending_todos(
        users_multiple_todos,
        attributes.slice(:project_id, :target_id, :target_type, :commit_id, :discussion, :action)
      ).distinct_user_ids
    end

    excluded_user_ids
  end

  def bulk_insert_todos(users, attributes)
    todos_ids = []

    users.each_slice(BATCH_SIZE) do |users_batch|
      todos_attributes = users_batch.map do |user|
        Todo.new(attributes.merge(user_id: user.id)).attributes.except('id', 'created_at', 'updated_at')
      end

      todos_ids += Todo.insert_all(todos_attributes, returning: :id).rows.flatten unless todos_attributes.blank?
    end

    Todo.id_in(todos_ids).to_a
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
    noteable = note.noteable
    discussion = note.discussion

    # Only update todos associated with the discussion if note is part of a thread
    # Otherwise, update all todos associated with the noteable
    #
    target = discussion.individual_note? ? noteable : discussion

    resolve_todos_for_target(target, author)
    create_mention_todos(project, noteable, author, note, skip_users)
  end

  def create_assignment_todo(target, author, old_assignees = [])
    if target.assignees.any?
      project = target.project
      assignees = target.assignees - old_assignees
      attributes = attributes_for_todo(project, target, author, Todo::ASSIGNED)

      create_todos(assignees, attributes, target_namespace(target), project)
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
    create_todos(directly_addressed_users, attributes, parent&.namespace, parent)

    # Create Todos for mentioned users
    mentioned_users = filter_mentioned_users(parent, note || target, author, skip_users + directly_addressed_users)
    attributes = attributes_for_todo(parent, target, author, Todo::MENTIONED, note)
    create_todos(mentioned_users, attributes, parent&.namespace, parent)
  end

  def create_build_failed_todo(merge_request, todo_author)
    project = merge_request.project
    attributes = attributes_for_todo(project, merge_request, todo_author, Todo::BUILD_FAILED)
    create_todos(todo_author, attributes, project.namespace, project)
  end

  def create_unmergeable_todo(merge_request, todo_author)
    project = merge_request.project
    attributes = attributes_for_todo(project, merge_request, todo_author, Todo::UNMERGEABLE)
    create_todos(todo_author, attributes, project.namespace, project)
  end

  def create_ssh_key_todos(ssh_keys, action)
    ssh_keys.each do |ssh_key|
      user = ssh_key.user
      attributes = {
        target_id: ssh_key.id,
        target_type: Key,
        action: action,
        author_id: user.id
      }
      create_todos(user, attributes, nil, nil)
    end
  end

  def attributes_for_target(target)
    attributes = {
      project_id: target&.project&.id,
      target_id: target.id,
      target_type: target.class.try(:polymorphic_name) || target.class.name,
      commit_id: nil
    }

    case target
    when Commit
      attributes.merge!(target_id: nil, commit_id: target.id)
    when Issue
      attributes[:issue_type] = target.issue_type
      attributes[:group] = target.namespace if target.project.blank?
    when DiscussionNote
      attributes.merge!(target_type: nil, target_id: nil, discussion: target.discussion)
    when Discussion
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
    PendingTodosFinder.new(criteria.merge(users: users)).execute
  end

  def track_todo_creation(user, issue_type, namespace, project)
    return unless issue_type == 'incident'

    event = "incident_management_incident_todo"
    track_usage_event(event, user.id)

    Gitlab::Tracking.event(
      self.class.to_s,
      event,
      project: project,
      namespace: namespace,
      user: user,
      label: 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly',
      context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event).to_context]
    )
  end

  def attributes_for_access_request_todos(source, author, action, note = nil)
    attributes = {
      target_id: source.id,
      target_type: source.class.polymorphic_name,
      author_id: author.id,
      action: action,
      note: note
    }

    if source.instance_of? Project
      attributes[:project_id] = source.id
      attributes[:group_id] = source.group.id if source.group.present?
    else
      attributes[:group_id] = source.id
    end

    attributes
  end

  def target_namespace(target)
    project = target.project
    project&.namespace || target.try(:namespace)
  end

  def work_item_activity_counter
    Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter
  end
end

TodoService.prepend_mod_with('TodoService')
