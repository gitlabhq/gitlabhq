# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Add expiry to all OAuth access tokens
    class ExpireOAuthTokens < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      operation_name :update_oauth_tokens
      feature_category :database

      def perform
        each_sub_batch(
          batching_scope: ->(relation) { relation.where(expires_in: nil) }
        ) do |sub_batch|
          update_oauth_tokens(sub_batch)
        end
      end

      private

      def update_oauth_tokens(relation)
        relation.update_all(expires_in: 7_200)
      end
    end
  end
end
