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

  def create_labels_note(issuable, added_labels, removed_labels)
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

  def filter_params(issuable_ability_name = :issue)
    filter_assignee
    filter_milestone
    filter_labels

    ability = :"admin_#{issuable_ability_name}"

    unless can?(current_user, ability, project)
      params.delete(:milestone_id)
      params.delete(:label_ids)
      params.delete(:assignee_id)
    end
  end

  def filter_assignee
    if params[:assignee_id] == IssuableFinder::NONE
      params[:assignee_id] = ''
    end
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
    return if params[:label_ids].to_a.empty?

    params[:label_ids] =
      project.labels.where(id: params[:label_ids]).pluck(:id)
  end

  def update(issuable)
    change_state(issuable)
    filter_params
    old_labels = issuable.labels.to_a

    if params.present? && issuable.update_attributes(params.merge(updated_by: current_user))
      issuable.reset_events_cache
      handle_common_system_notes(issuable, old_labels: old_labels)
      handle_changes(issuable)
      issuable.create_new_cross_references!(current_user)
      execute_hooks(issuable, 'update')
    end

    issuable
  end

  def change_state(issuable)
    case params.delete(:state_event)
    when 'reopen'
      reopen_service.new(project, current_user, {}).execute(issuable)
    when 'close'
      close_service.new(project, current_user, {}).execute(issuable)
    end
  end

  def handle_common_system_notes(issuable, options = {})
    if issuable.previous_changes.include?('title')
      create_title_change_note(issuable, issuable.previous_changes['title'].first)
    end

    if issuable.previous_changes.include?('description') && issuable.tasks?
      create_task_status_note(issuable)
    end

    old_labels = options[:old_labels]
    if old_labels && (issuable.labels != old_labels)
      create_labels_note(issuable, issuable.labels - old_labels, old_labels - issuable.labels)
    end
  end
end
