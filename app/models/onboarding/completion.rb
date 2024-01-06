# frozen_string_literal: true

module Onboarding
  class Completion
    include Gitlab::Utils::StrongMemoize

    ACTION_PATHS = [
      :pipeline_created,
      :trial_started,
      :required_mr_approvals_enabled,
      :code_owners_enabled,
      :issue_created,
      :git_write,
      :code_added,
      :merge_request_created,
      :user_added,
      :license_scanning_run,
      :secure_dependency_scanning_run,
      :secure_dast_run
    ].freeze

    def initialize(project, current_user = nil)
      @project = project
      @namespace = project.namespace
      @current_user = current_user
    end

    def percentage
      return 0 unless onboarding_progress

      total_actions = action_columns.count
      completed_actions = action_columns.count { |column| completed?(column) }

      (completed_actions.to_f / total_actions * 100).round
    end

    def completed?(column)
      attributes[column].present?
    end

    private

    def attributes
      onboarding_progress.attributes.symbolize_keys
    end
    strong_memoize_attr :attributes

    def onboarding_progress
      ::Onboarding::Progress.find_by(namespace: namespace)
    end
    strong_memoize_attr :onboarding_progress

    def action_columns
      ACTION_PATHS.map { |action_key| ::Onboarding::Progress.column_name(action_key) }
    end
    strong_memoize_attr :action_columns

    attr_reader :project, :namespace, :current_user
  end
end
