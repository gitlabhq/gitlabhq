# frozen_string_literal: true

module GraphqlTriggers
  def self.issuable_assignees_updated(issuable)
    GitlabSchema.subscriptions.trigger('issuableAssigneesUpdated', { issuable_id: issuable.to_gid }, issuable)
  end
end
