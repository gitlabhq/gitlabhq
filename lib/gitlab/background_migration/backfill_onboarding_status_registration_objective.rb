# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOnboardingStatusRegistrationObjective < BatchedMigrationJob
      operation_name :backfill_onboarding_status_registration_objective
      feature_category :onboarding

      def perform
        each_sub_batch do |sub_batch|
          UserDetail
            .where(user_id: sub_batch.select(:user_id))
            .where.not(registration_objective: nil)
            .where("(onboarding_status->'registration_objective') is null")
            .update_all(
              "onboarding_status = jsonb_set(
                COALESCE(onboarding_status, '{}'::jsonb),
                '{registration_objective}',
                to_jsonb(registration_objective)
              )"
            )
        end
      end
    end
  end
end
