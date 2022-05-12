# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Add expiry to all OAuth access tokens
    class ExpireOAuthTokens < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      def perform(batch_size)
        each_sub_batch(
          operation_name: :update_oauth_tokens,
          batching_scope: ->(relation) { relation.where(expires_in: nil) }
        ) do |sub_batch|
          update_oauth_tokens(sub_batch, batch_size)
        end
      end

      private

      def update_oauth_tokens(relation, batch_size)
        relation.update_all(expires_in: 7_200)
      end
    end
  end
end
