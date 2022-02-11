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
end
