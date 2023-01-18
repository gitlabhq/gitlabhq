# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Add expiry to all OAuth access tokens
    class ExpireOAuthTokens < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) { relation.where(expires_in: nil) }
      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(expires_in: 2.hours)
        end
      end
    end
  end
end
