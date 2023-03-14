# frozen_string_literal: true

module FeatureFlags
  class CreateService < FeatureFlags::BaseService
    def execute
      return error('Access Denied', 403) unless can_create?
      return error('Version is invalid', :bad_request) unless valid_version?

      ApplicationRecord.transaction do
        feature_flag = project.operations_feature_flags.new(params)

        if feature_flag.save
          update_last_feature_flag_updated_at!

          success(feature_flag: feature_flag)
        else
          error(feature_flag.errors.full_messages, 400)
        end
      end
    end

    private

    def audit_context(feature_flag)
      {
        name: 'feature_flag_created',
        message: audit_message(feature_flag),
        author: current_user,
        scope: feature_flag.project,
        target: feature_flag
      }
    end

    def audit_message(feature_flag)
      message_parts = ["Created feature flag #{feature_flag.name} with description \"#{feature_flag.description}\"."]

      message_parts += feature_flag.strategies.map do |strategy|
        created_strategy_message(strategy)
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
