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
end
