# frozen_string_literal: true

module FeatureFlags
  class BaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    AUDITABLE_ATTRIBUTES = %w(name description active).freeze

    protected

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

    def created_scope_message(scope)
      "Created rule <strong>#{scope.environment_scope}</strong> "\
      "and set it as <strong>#{scope.active ? "active" : "inactive"}</strong> "\
      "with strategies <strong>#{scope.strategies}</strong>."
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
  end
end
