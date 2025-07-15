# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUserDetailOnboardingUrl < BatchedMigrationJob
      operation_name :backfill_user_detail_onboarding_url
      feature_category :onboarding

      OLD_STEP_URL = "https://gitlab.com/users/sign_up/groups/new"
      NEW_STEP_URL = "/users/sign_up/groups/new"

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
         .where("onboarding_status ->> 'step_url' = ?", OLD_STEP_URL)
         .update_all(<<~SQL)
            onboarding_status = jsonb_set(
              onboarding_status,
              '{step_url}',
              '"#{NEW_STEP_URL}"'::jsonb
            )
          SQL
        end
      end
    end
  end
end
