# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateLegacyStepUrlsToWelcomePath < BatchedMigrationJob
      operation_name :update_legacy_step_urls_to_welcome_path
      feature_category :onboarding

      COMPANY_STEP_URL_PREFIX = "/users/sign_up/company"
      GROUPS_NEW_STEP_URL_PREFIX = "/users/sign_up/groups/new"
      NEW_STEP_URL = "/users/sign_up/welcome?migrating=true"

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(
              "onboarding_status ->> 'step_url' LIKE ? OR onboarding_status ->> 'step_url' LIKE ?",
              "#{ApplicationRecord.sanitize_sql_like(COMPANY_STEP_URL_PREFIX)}%",
              "#{ApplicationRecord.sanitize_sql_like(GROUPS_NEW_STEP_URL_PREFIX)}%"
            )
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
