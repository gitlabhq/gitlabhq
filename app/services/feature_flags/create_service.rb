# frozen_string_literal: true

module FeatureFlags
  class CreateService < FeatureFlags::BaseService
    def execute
      return error('Access Denied', 403) unless can_create?
      return error('Version is invalid', :bad_request) unless valid_version?

      ActiveRecord::Base.transaction do
        feature_flag = project.operations_feature_flags.new(params)

        if feature_flag.save
          save_audit_event(audit_event(feature_flag))

          success(feature_flag: feature_flag)
        else
          error(feature_flag.errors.full_messages, 400)
        end
      end
    end

    private

    def audit_message(feature_flag)
      message_parts = ["Created feature flag #{feature_flag.name} with description \"#{feature_flag.description}\"."]

      message_parts += feature_flag.scopes.map do |scope|
        created_scope_message(scope)
      end

      message_parts.join(" ")
    end

    def can_create?
      Ability.allowed?(current_user, :create_feature_flag, project)
    end

    def valid_version?
      !params.key?(:version) || Operations::FeatureFlag.versions.key?(params[:version])
    end
  end
end
