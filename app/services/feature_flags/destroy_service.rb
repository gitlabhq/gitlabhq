# frozen_string_literal: true

module FeatureFlags
  class DestroyService < FeatureFlags::BaseService
    def execute(feature_flag)
      destroy_feature_flag(feature_flag)
    end

    private

    def destroy_feature_flag(feature_flag)
      return error('Access Denied', 403) unless can_destroy?(feature_flag)

      ActiveRecord::Base.transaction do
        if feature_flag.destroy
          save_audit_event(audit_event(feature_flag))

          success(feature_flag: feature_flag)
        else
          error(feature_flag.errors.full_messages)
        end
      end
    end

    def audit_message(feature_flag)
      "Deleted feature flag #{feature_flag.name}."
    end

    def can_destroy?(feature_flag)
      Ability.allowed?(current_user, :destroy_feature_flag, feature_flag)
    end
  end
end
