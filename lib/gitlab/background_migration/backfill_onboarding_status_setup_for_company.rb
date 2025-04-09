# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOnboardingStatusSetupForCompany < BatchedMigrationJob
      operation_name :backfill_onboarding_status_setup_for_company
      feature_category :onboarding

      class UserDetail < ApplicationRecord
        self.table_name = :user_details

        belongs_to :user
      end

      def perform
        each_sub_batch do |sub_batch|
          UserDetail
            .where(user_id: sub_batch.select(:user_id))
            .where("(user_details.onboarding_status->'setup_for_company') IS NULL")
            .joins("INNER JOIN user_preferences ON user_details.user_id = user_preferences.user_id")
            .where.not(user_preferences: { setup_for_company: nil })
            .update_all(
              "onboarding_status = jsonb_set(
                COALESCE(onboarding_status, '{}'::jsonb),
                '{setup_for_company}',
                (SELECT to_jsonb(user_preferences.setup_for_company)
                 FROM user_preferences
                 WHERE user_details.user_id = user_preferences.user_id)
              )"
            )
        end
      end
    end
  end
end
