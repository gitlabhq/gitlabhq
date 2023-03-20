# frozen_string_literal: true

module FeatureFlags
  class DestroyService < FeatureFlags::BaseService
    def execute(feature_flag)
      destroy_feature_flag(feature_flag)
    end

    private

    def destroy_feature_flag(feature_flag)
      return error('Access Denied', 403) unless can_destroy?(feature_flag)

      ApplicationRecord.transaction do
        if feature_flag.destroy
          update_last_feature_flag_updated_at!

          success(feature_flag: feature_flag)
        else
          error(feature_flag.errors.full_messages)
        end
      end
    end

    def audit_context(feature_flag)
      {
        name: 'feature_flag_deleted',
        message: audit_message(feature_flag),
        author: current_user,
        scope: feature_flag.project,
        target: feature_flag
      }
    end

    def audit_message(feature_flag)
      "Deleted feature flag #{feature_flag.name}."
    end

    def can_destroy?(feature_flag)
      Ability.allowed?(current_user, :destroy_feature_flag, feature_flag)
    end
  end
end
