# frozen_string_literal: true

module FeatureFlags
  class BaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    AUDITABLE_ATTRIBUTES = %w[name description active].freeze

    def success(**args)
      sync_to_jira(args[:feature_flag])

      audit_event(args[:feature_flag], args[:audit_context])
      super
    end

    protected

    def audit_event(feature_flag, context = nil)
      context ||= audit_context(feature_flag)

      return if context[:message].blank?

      ::Gitlab::Audit::Auditor.audit(context)
    end

    def update_last_feature_flag_updated_at!
      Operations::FeatureFlagsClient.update_last_feature_flag_updated_at!(project)
    end

    def sync_to_jira(feature_flag)
      return unless feature_flag.present?
      return unless project.jira_subscription_exists?

      seq_id = ::Atlassian::JiraConnect::Client.generate_update_sequence_id
      feature_flag.run_after_commit do
        ::JiraConnect::SyncFeatureFlagsWorker.perform_async(feature_flag.id, seq_id)
      end
    end

    def created_strategy_message(strategy)
      scopes = strategy.scopes
                 .map { |scope| %("#{scope.environment_scope}") }
                 .join(', ')
      %(Created strategy "#{strategy.name}" with scopes #{scopes}.)
    end

    def feature_flag_by_name
      strong_memoize(:feature_flag_by_name) do
        project.operations_feature_flags.find_by_name(params[:name])
      end
    end

    def feature_flag_scope_by_environment_scope
      strong_memoize(:feature_flag_scope_by_environment_scope) do
        feature_flag_by_name.scopes.find_by_environment_scope(params[:environment_scope])
      end
    end

    private

    def audit_message(feature_flag)
      raise NotImplementedError, "This method should be overriden by subclasses"
    end
  end
end
