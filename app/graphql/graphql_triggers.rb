# frozen_string_literal: true

module GraphqlTriggers
  def self.issuable_assignees_updated(issuable)
    GitlabSchema.subscriptions.trigger(:issuable_assignees_updated, { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issue_crm_contacts_updated(issue)
    GitlabSchema.subscriptions.trigger(:issue_crm_contacts_updated, { issuable_id: issue.to_gid }, issue)
  end

  def self.issuable_title_updated(issuable)
    GitlabSchema.subscriptions.trigger(:issuable_title_updated, { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_description_updated(issuable)
    GitlabSchema.subscriptions.trigger(:issuable_description_updated, { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_labels_updated(issuable)
    GitlabSchema.subscriptions.trigger(:issuable_labels_updated, { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_dates_updated(issuable)
    GitlabSchema.subscriptions.trigger(:issuable_dates_updated, { issuable_id: issuable.to_gid }, issuable)
  end

  def self.issuable_milestone_updated(issuable)
    GitlabSchema.subscriptions.trigger(:issuable_milestone_updated, { issuable_id: issuable.to_gid }, issuable)
  end

  def self.work_item_note_created(work_item_gid, note_data)
    GitlabSchema.subscriptions.trigger(:work_item_note_created, { noteable_id: work_item_gid }, note_data)
  end

  def self.work_item_note_deleted(work_item_gid, note_data)
    GitlabSchema.subscriptions.trigger(:work_item_note_deleted, { noteable_id: work_item_gid }, note_data)
  end

  def self.work_item_note_updated(work_item_gid, note_data)
    GitlabSchema.subscriptions.trigger(:work_item_note_updated, { noteable_id: work_item_gid }, note_data)
  end

  def self.merge_request_reviewers_updated(merge_request)
    GitlabSchema.subscriptions.trigger(
      :merge_request_reviewers_updated, { issuable_id: merge_request.to_gid }, merge_request
    )
  end

  def self.merge_request_merge_status_updated(merge_request)
    GitlabSchema.subscriptions.trigger(
      :merge_request_merge_status_updated, { issuable_id: merge_request.to_gid }, merge_request
    )
  end

  def self.merge_request_approval_state_updated(merge_request)
    GitlabSchema.subscriptions.trigger(
      :merge_request_approval_state_updated, { issuable_id: merge_request.to_gid }, merge_request
    )
  end

  def self.merge_request_diff_generated(merge_request)
    GitlabSchema.subscriptions.trigger(
      :merge_request_diff_generated, { issuable_id: merge_request.to_gid }, merge_request
    )
  end

  def self.work_item_updated(work_item)
    # becomes is necessary here since this can be triggered with both a WorkItem and also an Issue
    # depending on the update service the call comes from
    work_item = work_item.becomes(::WorkItem) if work_item.is_a?(::Issue) # rubocop:disable Cop/AvoidBecomes

    ::GitlabSchema.subscriptions.trigger('workItemUpdated', { work_item_id: work_item.to_gid }, work_item)
  end

  def self.issuable_todo_updated(issuable)
    return unless issuable.respond_to?(:to_gid)

    ::GitlabSchema.subscriptions.trigger(
      :issuable_todo_updated, { issuable_id: issuable.to_gid }, issuable
    )
  end

  def self.user_merge_request_updated(user, merge_request)
    return unless Feature.enabled?(:merge_request_dashboard_realtime, user, type: :wip)

    GitlabSchema.subscriptions.trigger(:user_merge_request_updated, { user_id: user.to_gid }, merge_request)
  end
end

GraphqlTriggers.prepend_mod
