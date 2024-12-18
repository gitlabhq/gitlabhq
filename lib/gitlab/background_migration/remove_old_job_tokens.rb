# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RemoveOldJobTokens < BatchedMigrationJob
      operation_name :remove_old_tokens
      feature_category :continuous_integration

      ACTIVE_STATUSES = %w[
        waiting_for_resource
        preparing
        waiting_for_callback
        pending
        running
      ].freeze

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where.not(status: ACTIVE_STATUSES)
            .where.not(token_encrypted: nil)
            .where(created_at: ...1.month.ago)
            .update_all(token_encrypted: nil)
        end
      end
    end
  end
end
