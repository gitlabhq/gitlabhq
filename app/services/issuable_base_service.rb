class IssuableBaseService < BaseService
  private

  def create_assignee_note(issuable)
    Note.create_assignee_change_note(
      issuable, issuable.project, current_user, issuable.assignee)
  end

  def create_milestone_note(issuable)
    Note.create_milestone_change_note(
      issuable, issuable.project, current_user, issuable.milestone)
  end

  def create_labels_note(issuable, labels, removed = true)
    Note.create_labels_change_note(
        issuable, issuable.project, current_user, labels, removed)
  end
end
