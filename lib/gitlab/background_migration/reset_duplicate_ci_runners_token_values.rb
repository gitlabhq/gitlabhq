# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify duplicate token values in ci_runners table in batches
    class ResetDuplicateCiRunnersTokenValues < BatchedMigrationJob
      operation_name :nullify_duplicate_ci_runner_token_values
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          # Reset duplicate runner tokens that would prevent creating an unique index.
          nullify_duplicate_ci_runner_token_values(sub_batch)
        end
      end

      private

      def nullify_duplicate_ci_runner_token_values(sub_batch)
        batchable_model = define_batchable_model(batch_table, connection: connection)

        duplicate_tokens = batchable_model
                             .where(token: sub_batch.select(:token).distinct)
                             .group(:token)
                             .having('COUNT(*) > 1')
                             .pluck(:token)

        batchable_model.where(token: duplicate_tokens).update_all(token: nil) if duplicate_tokens.any?
      end
    end
  end
end
