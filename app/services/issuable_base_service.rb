class IssuableBaseService < BaseService
  prepend ::EE::IssuableBaseService

  private

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
    return unless params[:assignee_id].present?

    assignee_id = params[:assignee_id]

    if assignee_id.to_s == IssuableFinder::NONE
      params[:assignee_id] = ""
    else
      params.delete(:assignee_id) unless assignee_can_read?(issuable, assignee_id)
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

    milestone =
      Milestone.for_projects_and_groups([project.id], [project.group&.id]).find_by_id(milestone_id)

    params[:milestone_id] = '' unless milestone
  end

  def filter_labels
    filter_labels_in_param(:add_label_ids)
    filter_labels_in_param(:remove_label_ids)
    filter_labels_in_param(:label_ids)
    find_or_create_label_ids
  end

  def filter_labels_in_param(key)
    return if params[key].to_a.empty?

    params[key] = available_labels.where(id: params[key]).pluck(:id)
  end

  def find_or_create_label_ids
    labels = params.delete(:labels)

    return unless labels

    params[:label_ids] = labels.split(",").map do |label_name|
      label = Labels::FindOrCreateService.new(
        current_user,
        parent,
        title: label_name.strip,
        available_labels: available_labels
      ).execute

      label.try(:id)
    end.compact
  end

  def process_label_ids(attributes, existing_label_ids: nil)
    label_ids = attributes.delete(:label_ids)
    add_label_ids = attributes.delete(:add_label_ids)
    remove_label_ids = attributes.delete(:remove_label_ids)

    new_label_ids = existing_label_ids || label_ids || []

    if add_label_ids.blank? && remove_label_ids.blank?
      new_label_ids = label_ids if label_ids
    else
      new_label_ids |= add_label_ids if add_label_ids
      new_label_ids -= remove_label_ids if remove_label_ids
    end

    new_label_ids
  end

  def available_labels
    @available_labels ||= LabelsFinder.new(current_user, project_id: @project.id, include_ancestor_groups: true).execute
  end

  def handle_quick_actions_on_create(issuable)
    merge_quick_actions_into_params!(issuable)
  end

  def merge_quick_actions_into_params!(issuable)
    original_description = params.fetch(:description, issuable.description)

    description, command_params =
      QuickActions::InterpretService.new(project, current_user)
        .execute(original_description, issuable)

    # Avoid a description already set on an issuable to be overwritten by a nil
    params[:description] = description if description

    params.merge!(command_params)
  end

  def create_issuable(issuable, attributes, label_ids:)
    issuable.with_transaction_returning_status do
      if issuable.save
        issuable.update_attributes(label_ids: label_ids)
      end
    end
  end

  def create(issuable)
    handle_quick_actions_on_create(issuable)
    filter_params(issuable)

    params.delete(:state_event)
    params[:author] ||= current_user

    label_ids = process_label_ids(params)

    issuable.assign_attributes(params)

    before_create(issuable)

    if params.present? && create_issuable(issuable, params, label_ids: label_ids)
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

  def before_update(issuable)
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
    params[:label_ids] = label_ids if labels_changing?(issuable.label_ids, label_ids)

    if issuable.changed? || params.present?
      issuable.assign_attributes(params.merge(updated_by: current_user))

      if has_title_or_description_changed?(issuable)
        issuable.assign_attributes(last_edited_at: Time.now, last_edited_by: current_user)
      end

      before_update(issuable)

      # We have to perform this check before saving the issuable as Rails resets
      # the changed fields upon calling #save.
      update_project_counters = issuable.project && update_project_counter_caches?(issuable)

      if issuable.with_transaction_returning_status { issuable.save }
        # We do not touch as it will affect a update on updated_at field
        ActiveRecord::Base.no_touching do
          Issuable::CommonSystemNotesService.new(project, current_user).execute(issuable, old_associations[:labels])
        end

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

  def change_todo(issuable)
    case params.delete(:todo_event)
    when 'add'
      todo_service.mark_todo(issuable, current_user)
    when 'done'
      todo = TodosFinder.new(current_user).find_by(target: issuable)
      todo_service.mark_todos_as_done_by_ids(todo, current_user) if todo
    end
  end

  def toggle_award(issuable)
    award = params.delete(:emoji_award)
    if award
      todo_service.new_award_emoji(issuable, current_user)
      issuable.toggle_award_emoji(award, current_user)
    end
  end

  def associations_before_update(issuable)
    associations =
      {
        labels: issuable.labels.to_a,
        mentioned_users: issuable.mentioned_users.to_a,
        assignees: issuable.assignees.to_a
      }
    associations[:total_time_spent] = issuable.total_time_spent if issuable.respond_to?(:total_time_spent)

    associations
  end

  def has_changes?(issuable, old_labels: [], old_assignees: [])
    valid_attrs = [:title, :description, :assignee_id, :milestone_id, :target_branch]

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
  def execute_hooks(issuable, action = 'open', params = {})
  end

  def update_project_counter_caches?(issuable)
    issuable.state_changed?
  end

  def parent
    project
  end
end
