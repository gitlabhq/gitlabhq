# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOnboardingStatusRole < BatchedMigrationJob
      operation_name :backfill_onboarding_status_role # This is used as the key on collecting metrics
      feature_category :onboarding

      scope_to ->(relation) { relation.where.not(role: nil) }

      def perform
        each_sub_batch do |sub_batch|
          UserDetail
            .where(user: sub_batch)
            .where("(onboarding_status->'role') is null")
            .update_all(
              "onboarding_status = jsonb_set(
              	COALESCE(onboarding_status, '{}'::jsonb),'{role}',to_jsonb(
              		(SELECT role FROM users WHERE users.id = user_details.user_id)
              	)
              )"
            )
        end
      end
    end
  end
end
