# frozen_string_literal: true

module LearnGitlab
  class Onboarding
    include Gitlab::Utils::StrongMemoize

    ACTION_ISSUE_IDS = {
      pipeline_created: 7,
      trial_started: 2,
      required_mr_approvals_enabled: 11,
      code_owners_enabled: 10
    }.freeze

    ACTION_PATHS = [
      :issue_created,
      :git_write,
      :merge_request_created,
      :user_added,
      :security_scan_enabled
    ].freeze

    def initialize(namespace)
      @namespace = namespace
    end

    def completed_percentage
      return 0 unless onboarding_progress

      attributes = onboarding_progress.attributes.symbolize_keys

      total_actions = action_columns.count
      completed_actions = action_columns.count { |column| attributes[column].present? }

      (completed_actions.to_f / total_actions.to_f * 100).round
    end

    private

    def onboarding_progress
      strong_memoize(:onboarding_progress) do
        OnboardingProgress.find_by(namespace: namespace) # rubocop: disable CodeReuse/ActiveRecord
      end
    end

    def action_columns
      strong_memoize(:action_columns) do
        tracked_actions.map { |action_key| OnboardingProgress.column_name(action_key) }
      end
    end

    def tracked_actions
      ACTION_ISSUE_IDS.keys + ACTION_PATHS
    end

    attr_reader :namespace
  end
end
