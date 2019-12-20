# frozen_string_literal: true

class IssuableBaseService < BaseService
  private

  attr_accessor :params, :skip_milestone_email

  def initialize(project, user = nil, params = {})
    super

    @skip_milestone_email = @params.delete(:skip_milestone_email)
  end

  def filter_params(issuable)
    ability_name = :"admin_#{issuable.to_ability_name}"

    unless can?(current_user, ability_name, issuable)
      params.delete(:milestone_id)
      params.delete(:labels)
      params.delete(:add_label_ids)
      params.delete(:remove_label_ids)
      params.delete(:label_ids)
      params.delete(:assignee_ids)
      params.delete(:assignee_id)
      params.delete(:due_date)
      params.delete(:canonical_issue_id)
      params.delete(:project)
      params.delete(:discussion_locked)
    end

    filter_assignee(issuable)
    filter_milestone
    filter_labels
  end

  def filter_assignee(issuable)
    return if params[:assignee_ids].blank?

    unless issuable.allows_multiple_assignees?
      params[:assignee_ids] = params[:assignee_ids].first(1)
    end

    assignee_ids = params[:assignee_ids].select { |assignee_id| assignee_can_read?(issuable, assignee_id) }

    if params[:assignee_ids].map(&:to_s) == [IssuableFinder::NONE]
      params[:assignee_ids] = []
    elsif assignee_ids.any?
      params[:assignee_ids] = assignee_ids
    else
      params.delete(:assignee_ids)
    end
  end

  def assignee_can_read?(issuable, assignee_id)
    new_assignee = User.find_by_id(assignee_id)

    return false unless new_assignee

    ability_name = :"read_#{issuable.to_ability_name}"
    resource     = issuable.persisted? ? issuable : project

    can?(new_assignee, ability_name, resource)
  end

  def filter_milestone
    milestone_id = params[:milestone_id]
    return unless milestone_id

    params[:milestone_id] = '' if milestone_id == IssuableFinder::NONE
    groups = project.group&.self_and_ancestors&.select(:id)

    milestone =
      Milestone.for_projects_and_groups([project.id], groups).find_by_id(milestone_id)

    params[:milestone_id] = '' unless milestone
  end

  def filter_labels
    label_ids_to_filter(:add_label_ids, :add_labels, false)
    label_ids_to_filter(:remove_label_ids, :remove_labels, true)
    label_ids_to_filter(:label_ids, :labels, false)
  end

  def label_ids_to_filter(label_id_key, label_key, find_only)
    if params[label_id_key]
      params[label_id_key] = labels_service.filter_labels_ids_in_param(label_id_key)
    elsif params[label_key]
      params[label_id_key] = labels_service.find_or_create_by_titles(label_key, find_only: find_only).map(&:id)
    end
  end

  def filter_labels_in_param(key)
    return if params[key].to_a.empty?

    params[key] = available_labels.id_in(params[key]).pluck_primary_key
  end

  def find_or_create_label_ids
    labels = params.delete(:labels)

    return unless labels

    params[:label_ids] = labels.map do |label_name|
      label = Labels::FindOrCreateService.new(
        current_user,
        parent,
        title: label_name.strip,
        available_labels: available_labels
      ).execute

      label.try(:id)
    end.compact
  end

  def labels_service
    @labels_service ||= ::Labels::AvailableLabelsService.new(current_user, parent, params)
  end

  def process_label_ids(attributes, existing_label_ids: nil, extra_label_ids: [])
    label_ids = attributes.delete(:label_ids)
    add_label_ids = attributes.delete(:add_label_ids)
    remove_label_ids = attributes.delete(:remove_label_ids)

    new_label_ids = existing_label_ids || label_ids || []
    new_label_ids |= extra_label_ids

    if add_label_ids.blank? && remove_label_ids.blank?
      new_label_ids = label_ids if label_ids
    else
      new_label_ids |= add_label_ids if add_label_ids
      new_label_ids -= remove_label_ids if remove_label_ids
    end

    new_label_ids.uniq
  end

  def handle_quick_actions_on_create(issuable)
    merge_quick_actions_into_params!(issuable)
  end

  def merge_quick_actions_into_params!(issuable, only: nil)
    original_description = params.fetch(:description, issuable.description)

    description, command_params =
      QuickActions::InterpretService.new(project, current_user)
        .execute(original_description, issuable, only: only)

    # Avoid a description already set on an issuable to be overwritten by a nil
    params[:description] = description if description

    params.merge!(command_params)
  end

  def create(issuable)
    handle_quick_actions_on_create(issuable)
    filter_params(issuable)

    params.delete(:state_event)
    params[:author] ||= current_user
    params[:label_ids] = process_label_ids(params, extra_label_ids: issuable.label_ids.to_a)

    issuable.assign_attributes(params)

    before_create(issuable)

    issuable_saved = issuable.with_transaction_returning_status do
      issuable.save && issuable.store_mentions!
    end

    if issuable_saved
      Issuable::CommonSystemNotesService.new(project, current_user).execute(issuable, is_update: false)

      after_create(issuable)
      execute_hooks(issuable)
      invalidate_cache_counts(issuable, users: issuable.assignees)
      issuable.update_project_counter_caches
    end

    issuable
  end

  def before_create(issuable)
    # To be overridden by subclasses
  end

  def after_create(issuable)
    # To be overridden by subclasses
  end

  def before_update(issuable, skip_spam_check: false)
    # To be overridden by subclasses
  end

  def after_update(issuable)
    # To be overridden by subclasses
  end

  def update(issuable)
    change_state(issuable)
    change_subscription(issuable)
    change_todo(issuable)
    toggle_award(issuable)
    filter_params(issuable)
    old_associations = associations_before_update(issuable)

    label_ids = process_label_ids(params, existing_label_ids: issuable.label_ids)
    if labels_changing?(issuable.label_ids, label_ids)
      params[:label_ids] = label_ids
      issuable.touch
    end

    if issuable.changed? || params.present?
      issuable.assign_attributes(params)

      if has_title_or_description_changed?(issuable)
        issuable.assign_attributes(last_edited_at: Time.now, last_edited_by: current_user)
      end

      before_update(issuable)

      # Do not touch when saving the issuable if only changes position within a list. We should call
      # this method at this point to capture all possible changes.
      should_touch = update_timestamp?(issuable)

      issuable.updated_by = current_user if should_touch
      # We have to perform this check before saving the issuable as Rails resets
      # the changed fields upon calling #save.
      update_project_counters = issuable.project && update_project_counter_caches?(issuable)
      ensure_milestone_available(issuable)

      issuable_saved = issuable.with_transaction_returning_status do
        issuable.save(touch: should_touch) && issuable.store_mentions!
      end

      if issuable_saved
        Issuable::CommonSystemNotesService.new(project, current_user).execute(issuable, old_labels: old_associations[:labels])

        handle_changes(issuable, old_associations: old_associations)

        new_assignees = issuable.assignees.to_a
        affected_assignees = (old_associations[:assignees] + new_assignees) - (old_associations[:assignees] & new_assignees)

        invalidate_cache_counts(issuable, users: affected_assignees.compact)
        after_update(issuable)
        issuable.create_new_cross_references!(current_user)
        execute_hooks(
          issuable,
          'update',
          old_associations: old_associations
        )

        issuable.update_project_counter_caches if update_project_counters
      end
    end

    issuable
  end

  def update_task(issuable)
    filter_params(issuable)

    if issuable.changed? || params.present?
      issuable.assign_attributes(params.merge(updated_by: current_user,
                                              last_edited_at: Time.now,
                                              last_edited_by: current_user))

      before_update(issuable, skip_spam_check: true)

      if issuable.with_transaction_returning_status { issuable.save }
        Issuable::CommonSystemNotesService.new(project, current_user).execute(issuable, old_labels: nil)

        handle_task_changes(issuable)
        invalidate_cache_counts(issuable, users: issuable.assignees.to_a)
        after_update(issuable)
        execute_hooks(issuable, 'update', old_associations: nil)
      end
    end

    issuable
  end

  # Handle the `update_task` event sent from UI.  Attempts to update a specific
  # line in the markdown and cached html, bypassing any unnecessary updates or checks.
  def update_task_event(issuable)
    update_task_params = params.delete(:update_task)
    return unless update_task_params

    tasklist_toggler = TaskListToggleService.new(issuable.description, issuable.description_html,
                                                 line_source: update_task_params[:line_source],
                                                 line_number: update_task_params[:line_number].to_i,
                                                 toggle_as_checked: update_task_params[:checked])

    unless tasklist_toggler.execute
      # if we make it here, the data is much newer than we thought it was - fail fast
      raise ActiveRecord::StaleObjectError
    end

    # by updating the description_html field at the same time,
    # the markdown cache won't be considered invalid
    params[:description]      = tasklist_toggler.updated_markdown
    params[:description_html] = tasklist_toggler.updated_markdown_html

    # since we're updating a very specific line, we don't care whether
    # the `lock_version` sent from the FE is the same or not.  Just
    # make sure the data hasn't changed since we queried it
    params[:lock_version]     = issuable.lock_version

    update_task(issuable)
  end

  def labels_changing?(old_label_ids, new_label_ids)
    old_label_ids.sort != new_label_ids.sort
  end

  def has_title_or_description_changed?(issuable)
    issuable.title_changed? || issuable.description_changed?
  end

  def change_state(issuable)
    case params.delete(:state_event)
    when 'reopen'
      reopen_service.new(project, current_user, {}).execute(issuable)
    when 'close'
      close_service.new(project, current_user, {}).execute(issuable)
    end
  end

  def change_subscription(issuable)
    case params.delete(:subscription_event)
    when 'subscribe'
      issuable.subscribe(current_user, project)
    when 'unsubscribe'
      issuable.unsubscribe(current_user, project)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def change_todo(issuable)
    case params.delete(:todo_event)
    when 'add'
      todo_service.mark_todo(issuable, current_user)
    when 'done'
      todo = TodosFinder.new(current_user).find_by(target: issuable)
      todo_service.mark_todos_as_done_by_ids(todo, current_user) if todo
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def toggle_award(issuable)
    award = params.delete(:emoji_award)
    AwardEmojis::ToggleService.new(issuable, award, current_user).execute if award
  end

  def associations_before_update(issuable)
    associations =
      {
        labels: issuable.labels.to_a,
        mentioned_users: issuable.mentioned_users(current_user).to_a,
        assignees: issuable.assignees.to_a
      }
    associations[:total_time_spent] = issuable.total_time_spent if issuable.respond_to?(:total_time_spent)
    associations[:description] = issuable.description

    associations
  end

  def has_changes?(issuable, old_labels: [], old_assignees: [])
    valid_attrs = [:title, :description, :assignee_ids, :milestone_id, :target_branch]

    attrs_changed = valid_attrs.any? do |attr|
      issuable.previous_changes.include?(attr.to_s)
    end

    labels_changed = issuable.labels != old_labels

    assignees_changed = issuable.assignees != old_assignees

    attrs_changed || labels_changed || assignees_changed
  end

  def invalidate_cache_counts(issuable, users: [])
    users.each do |user|
      user.public_send("invalidate_#{issuable.model_name.singular}_cache_counts") # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  # override if needed
  def handle_changes(issuable, options)
  end

  # override if needed
  def handle_task_changes(issuable)
  end

  # override if needed
  def execute_hooks(issuable, action = 'open', params = {})
  end

  def update_project_counter_caches?(issuable)
    issuable.state_id_changed?
  end

  def parent
    project
  end

  # we need to check this because milestone from milestone_id param is displayed on "new" page
  # where private project milestone could leak without this check
  def ensure_milestone_available(issuable)
    issuable.milestone_id = nil unless issuable.milestone_available?
  end

  def update_timestamp?(issuable)
    issuable.changes.keys != ["relative_position"]
  end
end

IssuableBaseService.prepend_if_ee('EE::IssuableBaseService')
