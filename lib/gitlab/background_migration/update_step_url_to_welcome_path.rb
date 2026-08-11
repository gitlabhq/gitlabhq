# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateStepUrlToWelcomePath < BatchedMigrationJob
      operation_name :update_step_url_to_welcome_path
      feature_category :onboarding

      COMPANY_STEP_URL = "/users/sign_up/company"
      GROUPS_NEW_STEP_URL = "/users/sign_up/groups/new"
      NEW_STEP_URL = "/users/sign_up/welcome?migrating=true"

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where("onboarding_status ->> 'step_url' IN (?, ?)", COMPANY_STEP_URL, GROUPS_NEW_STEP_URL)
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
