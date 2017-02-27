class IssuableBaseService < BaseService
  private

  def create_assignee_note(issuable)
    SystemNoteService.change_assignee(
      issuable, issuable.project, current_user, issuable.assignee)
  end

  def create_milestone_note(issuable)
    SystemNoteService.change_milestone(
      issuable, issuable.project, current_user, issuable.milestone)
  end

  def create_labels_note(issuable, old_labels)
    added_labels = issuable.labels - old_labels
    removed_labels = old_labels - issuable.labels

    SystemNoteService.change_label(
      issuable, issuable.project, current_user, added_labels, removed_labels)
  end

  def create_title_change_note(issuable, old_title)
    SystemNoteService.change_title(
      issuable, issuable.project, current_user, old_title)
  end

  def create_branch_change_note(issuable, branch_type, old_branch, new_branch)
    SystemNoteService.change_branch(
      issuable, issuable.project, current_user, branch_type,
      old_branch, new_branch)
  end

  def create_task_status_note(issuable)
    issuable.updated_tasks.each do |task|
      SystemNoteService.change_task_status(issuable, issuable.project, current_user, task)
    end
  end

  def create_time_estimate_note(issuable)
    SystemNoteService.change_time_estimate(issuable, issuable.project, current_user)
  end

  def create_time_spent_note(issuable)
    SystemNoteService.change_time_spent(issuable, issuable.project, current_user)
  end

  def filter_params(issuable)
    ability_name = :"admin_#{issuable.to_ability_name}"

    unless can?(current_user, ability_name, project)
      params.delete(:milestone_id)
      params.delete(:labels)
      params.delete(:add_label_ids)
      params.delete(:remove_label_ids)
      params.delete(:label_ids)
      params.delete(:assignee_id)
      params.delete(:due_date)
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

    return false unless new_assignee.present?

    ability_name = :"read_#{issuable.to_ability_name}"
    resource     = issuable.persisted? ? issuable : project

    can?(new_assignee, ability_name, resource)
  end

  def filter_milestone
    milestone_id = params[:milestone_id]
    return unless milestone_id

    if milestone_id == IssuableFinder::NONE ||
        project.milestones.find_by(id: milestone_id).nil?
      params[:milestone_id] = ''
    end
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
      service = Labels::FindOrCreateService.new(current_user, project, title: label_name.strip)
      label   = service.execute

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
    LabelsFinder.new(current_user, project_id: @project.id).execute
  end

  def merge_slash_commands_into_params!(issuable)
    description, command_params =
      SlashCommands::InterpretService.new(project, current_user).
        execute(params[:description], issuable)

    # Avoid a description already set on an issuable to be overwritten by a nil
    params[:description] = description if params.has_key?(:description)

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
    merge_slash_commands_into_params!(issuable)
    filter_params(issuable)

    params.delete(:state_event)
    params[:author] ||= current_user

    label_ids = process_label_ids(params)

    issuable.assign_attributes(params)

    before_create(issuable)

    if params.present? && create_issuable(issuable, params, label_ids: label_ids)
      after_create(issuable)
      issuable.create_cross_references!(current_user)
      execute_hooks(issuable)
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
    filter_params(issuable)
    old_labels = issuable.labels.to_a
    old_mentioned_users = issuable.mentioned_users.to_a

    label_ids = process_label_ids(params, existing_label_ids: issuable.label_ids)
    params[:label_ids] = label_ids if labels_changing?(issuable.label_ids, label_ids)

    if params.present?
      issuable.assign_attributes(params.merge(updated_by: current_user))

      before_update(issuable)

      if issuable.with_transaction_returning_status { issuable.save }
        # We do not touch as it will affect a update on updated_at field
        ActiveRecord::Base.no_touching do
          handle_common_system_notes(issuable, old_labels: old_labels)
        end

        handle_changes(issuable, old_labels: old_labels, old_mentioned_users: old_mentioned_users)
        after_update(issuable)
        issuable.create_new_cross_references!(current_user)
        execute_hooks(issuable, 'update')
      end
    end

    issuable
  end

  def labels_changing?(old_label_ids, new_label_ids)
    old_label_ids.sort != new_label_ids.sort
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
      todo = TodosFinder.new(current_user).execute.find_by(target: issuable)
      todo_service.mark_todos_as_done([todo], current_user) if todo
    end
  end

  def has_changes?(issuable, old_labels: [])
    valid_attrs = [:title, :description, :assignee_id, :milestone_id, :target_branch]

    attrs_changed = valid_attrs.any? do |attr|
      issuable.previous_changes.include?(attr.to_s)
    end

    labels_changed = issuable.labels != old_labels

    attrs_changed || labels_changed
  end

  def handle_common_system_notes(issuable, old_labels: [])
    if issuable.previous_changes.include?('title')
      create_title_change_note(issuable, issuable.previous_changes['title'].first)
    end

    if issuable.previous_changes.include?('description') && issuable.tasks?
      create_task_status_note(issuable)
    end

    if issuable.previous_changes.include?('time_estimate')
      create_time_estimate_note(issuable)
    end

    if issuable.time_spent?
      create_time_spent_note(issuable)
    end

    create_labels_note(issuable, old_labels) if issuable.labels != old_labels
  end
end
