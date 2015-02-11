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

  def create_labels_note(issuable, labels1, labels2, removed = true)
    diff_labels = labels1 - labels2
    Note.create_labels_change_note(
        issuable, issuable.project, current_user, diff_labels, removed
    ) unless diff_labels.empty?
  end
end
