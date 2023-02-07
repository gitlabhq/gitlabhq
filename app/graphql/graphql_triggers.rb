# frozen_string_literal: true

module GraphqlTriggers
  def self.issuable_assignees_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableAssigneesUpdated', { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issue_crm_contacts_updated(issue)
    GitlabSchema.subscriptions.trigger('issueCrmContactsUpdated', { issuable_id: issue.to_gid }, issue)
  end

  def self.issuable_title_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableTitleUpdated', { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_description_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableDescriptionUpdated', { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_labels_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableLabelsUpdated', { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_dates_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableDatesUpdated', { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_milestone_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableMilestoneUpdated', { issuable_id: issuable.to_gid }, issuable)
  end

  def self.work_item_note_created(work_item_gid, note_data)
    GitlabSchema.subscriptions.trigger('workItemNoteCreated', { noteable_id: work_item_gid }, note_data)
  end

  def self.work_item_note_deleted(work_item_gid, note_data)
    GitlabSchema.subscriptions.trigger('workItemNoteDeleted', { noteable_id: work_item_gid }, note_data)
  end

  def self.work_item_note_updated(work_item_gid, note_data)
    GitlabSchema.subscriptions.trigger('workItemNoteUpdated', { noteable_id: work_item_gid }, note_data)
  end

  def self.merge_request_reviewers_updated(merge_request)
    GitlabSchema.subscriptions.trigger(
      'mergeRequestReviewersUpdated', { issuable_id: merge_request.to_gid }, merge_request
    )
  end

  def self.merge_request_merge_status_updated(merge_request)
    GitlabSchema.subscriptions.trigger(
      'mergeRequestMergeStatusUpdated', { issuable_id: merge_request.to_gid }, merge_request
    )
  end

  def self.merge_request_approval_state_updated(merge_request)
    GitlabSchema.subscriptions.trigger(
      'mergeRequestApprovalStateUpdated', { issuable_id: merge_request.to_gid }, merge_request
    )
  end
end

GraphqlTriggers.prepend_mod
