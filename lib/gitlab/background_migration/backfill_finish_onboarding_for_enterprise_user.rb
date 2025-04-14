# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillFinishOnboardingForEnterpriseUser < BatchedMigrationJob
      operation_name :backfill_finish_onboarding_for_enterprise_user # This is used as the key on collecting metrics
      feature_category :onboarding

      class UserDetail < ApplicationRecord
        self.table_name = :user_details

        belongs_to :user
      end

      class User < ApplicationRecord
        self.table_name = :users
      end

      def perform
        each_sub_batch do |sub_batch|
          user_ids = UserDetail
            .where(user: sub_batch.where(onboarding_in_progress: true))
            .where.not(enterprise_group_id: nil)
            .pluck(:user_id)

          User.where(id: user_ids).update_all(onboarding_in_progress: false)
        end
      end
    end
  end
end
