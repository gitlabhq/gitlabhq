# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Clean up personal access tokens with expires_at value is nil
    # and set the value to new default 365 days
    class CleanupPersonalAccessTokensWithNilExpiresAt < BatchedMigrationJob
      feature_category :system_access

      EXPIRES_AT_DEFAULT = 365.days.from_now

      scope_to ->(relation) { relation.where(expires_at: nil) }
      operation_name :update_all

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(expires_at: EXPIRES_AT_DEFAULT)
        end
      end
    end
  end
end
