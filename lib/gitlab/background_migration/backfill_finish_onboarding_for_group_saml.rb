# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillFinishOnboardingForGroupSaml < BatchedMigrationJob
      operation_name :backfill_finish_onboarding_for_group_saml # This is used as the key on collecting metrics
      scope_to ->(relation) { relation.where(provider: 'group_saml') }
      feature_category :onboarding

      class User < ApplicationRecord
        self.table_name = :users
      end

      def perform
        each_sub_batch do |sub_batch|
          # First get the user IDs from the identities query
          user_ids = sub_batch
                       .joins("INNER JOIN users ON users.id = identities.user_id")
                       .where(provider: 'group_saml', users: { onboarding_in_progress: true })
                       .pluck(:user_id)

          # Then update those users
          User.where(id: user_ids).update_all(onboarding_in_progress: false)
        end
      end
    end
  end
end
