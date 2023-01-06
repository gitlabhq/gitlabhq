# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify duplicate token_encrypted values in ci_runners table in batches
    class ResetDuplicateCiRunnersTokenEncryptedValues < BatchedMigrationJob
      operation_name :nullify_duplicate_ci_runner_token_encrypted_values
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          # Reset duplicate runner encrypted tokens that would prevent creating an unique index.
          nullify_duplicate_ci_runner_token_encrypted_values(sub_batch)
        end
      end

      private

      def nullify_duplicate_ci_runner_token_encrypted_values(sub_batch)
        batchable_model = define_batchable_model(batch_table, connection: connection)

        duplicate_tokens = batchable_model
                             .where(token_encrypted: sub_batch.select(:token_encrypted).distinct)
                             .group(:token_encrypted)
                             .having('COUNT(*) > 1')
                             .pluck(:token_encrypted)

        return if duplicate_tokens.empty?

        batchable_model.where(token_encrypted: duplicate_tokens).update_all(token_encrypted: nil)
      end
    end
  end
end
