# frozen_string_literal: true

class OnboardingProgress < ApplicationRecord
  belongs_to :namespace, optional: false

  validate :namespace_is_root_namespace

  ACTIONS = [
    :git_pull,
    :git_write,
    :merge_request_created,
    :pipeline_created,
    :user_added,
    :trial_started,
    :subscription_created,
    :required_mr_approvals_enabled,
    :code_owners_enabled,
    :scoped_label_created,
    :security_scan_enabled,
    :issue_auto_closed,
    :repository_imported,
    :repository_mirrored
  ].freeze

  class << self
    def onboard(namespace)
      return unless root_namespace?(namespace)

      safe_find_or_create_by(namespace: namespace)
    end

    def register(namespace, action)
      return unless root_namespace?(namespace) && ACTIONS.include?(action)

      action_column = column_name(action)
      onboarding_progress = find_by(namespace: namespace, action_column => nil)
      onboarding_progress&.update!(action_column => Time.current)
    end

    def completed?(namespace, action)
      return unless root_namespace?(namespace) && ACTIONS.include?(action)

      action_column = column_name(action)
      where(namespace: namespace).where.not(action_column => nil).exists?
    end

    private

    def column_name(action)
      :"#{action}_at"
    end

    def root_namespace?(namespace)
      namespace && namespace.root?
    end
  end

  private

  def namespace_is_root_namespace
    return unless namespace

    errors.add(:namespace, _('must be a root namespace')) if namespace.has_parent?
  end
end
