# frozen_string_literal: true

module FeatureFlags
  class BaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    AUDITABLE_ATTRIBUTES = %w(name description active).freeze

    def success(**args)
      audit_event = args.fetch(:audit_event) { audit_event(args[:feature_flag]) }
      save_audit_event(audit_event)
      sync_to_jira(args[:feature_flag])
      super
    end

    protected

    def update_last_feature_flag_updated_at!
      Operations::FeatureFlagsClient.update_last_feature_flag_updated_at!(project)
    end

    def audit_event(feature_flag)
      message = audit_message(feature_flag)

      return if message.blank?

      details =
        {
          custom_message: message,
          target_id: feature_flag.id,
          target_type: feature_flag.class.name,
          target_details: feature_flag.name
        }

      ::AuditEventService.new(
        current_user,
        feature_flag.project,
        details
      )
    end

    def save_audit_event(audit_event)
      return unless audit_event

      audit_event.security_event
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
                 .map { |scope| %Q("#{scope.environment_scope}") }
                 .join(', ')
      %Q(Created strategy "#{strategy.name}" with scopes #{scopes}.)
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
