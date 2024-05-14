# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOnboardingStatusStepUrl < BatchedMigrationJob
      operation_name :backfill_onboarding_status_step_url # This is used as the key on collecting metrics
      feature_category :onboarding

      class UserDetail < ApplicationRecord
        self.table_name = :user_details

        belongs_to :user
      end

      def perform
        each_sub_batch do |sub_batch|
          UserDetail
            .where(user: sub_batch.where(onboarding_in_progress: true))
            .where("(onboarding_status->'step_url') is null")
            .update_all("onboarding_status = jsonb_build_object('step_url', \"onboarding_step_url\")")
        end
      end
    end
  end
end
