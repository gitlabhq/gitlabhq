# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class EncryptMissedCiRunnerTokens < BatchedMigrationJob
      operation_name :encrypt_missed_ci_runner_tokens
      feature_category :fleet_visibility

      def perform
        each_sub_batch(
          batching_scope: ->(relation) { relation.where.not(token: nil).where(token_encrypted: nil) }
        ) do |runners_to_encrypt|
          token_encrypted_cases = []
          runner_ids = []

          runners_to_encrypt.pluck(:id, :token).each do |id, token|
            encrypted_token = encode(token)

            token_encrypted_cases <<
              "WHEN id = #{connection.quote(id)} THEN #{connection.quote(encrypted_token)}"
            runner_ids << connection.quote(id)
          end

          next if token_encrypted_cases.empty?

          connection.execute(
            <<~SQL
              UPDATE ci_runners
              SET token_encrypted = CASE
                    #{token_encrypted_cases.join(' ')}
                  END,
                  token = NULL
              WHERE id IN (#{runner_ids.join(',')})
            SQL
          )
        end
      end

      private

      def encode(token)
        Authn::TokenField::EncryptionHelper.encrypt_token(token)
      end
    end
  end
end
