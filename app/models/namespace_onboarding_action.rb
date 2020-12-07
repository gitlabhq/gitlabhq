# frozen_string_literal: true

class NamespaceOnboardingAction < ApplicationRecord
  belongs_to :namespace, optional: false

  validates :action, presence: true

  ACTIONS = {
    subscription_created: 1,
    git_write: 2,
    merge_request_created: 3,
    git_read: 4
  }.freeze

  enum action: ACTIONS

  class << self
    def completed?(namespace, action)
      where(namespace: namespace, action: action).exists?
    end

    def create_action(namespace, action)
      NamespaceOnboardingAction.safe_find_or_create_by(namespace: namespace, action: action)
    end
  end
end
