# frozen_string_literal: true

class NamespaceOnboardingAction < ApplicationRecord
  belongs_to :namespace, optional: false

  validates :action, presence: true

  ACTIONS = {
    subscription_created: 1,
    git_write: 2,
    merge_request_created: 3,
    git_read: 4,
    pipeline_created: 5,
    user_added: 6
  }.freeze

  # The monitoring window prevents the recording of a namespace_onboarding_action if a namespace is created before this
  # time span. We are not interested in older namspaces, because the purpose of this table is to monitor and act on the
  # progress of newly created namespaces or namespaces that already have at least one recorded action.
  MONITORING_WINDOW = 90.days

  enum action: ACTIONS

  class << self
    def completed?(namespace, action)
      where(namespace: namespace, action: action).exists?
    end

    def create_action(namespace, action)
      return unless namespace.root?
      return if namespace.created_at < MONITORING_WINDOW.ago && !namespace.namespace_onboarding_actions.exists?

      NamespaceOnboardingAction.safe_find_or_create_by(namespace: namespace, action: action)
    end
  end
end
