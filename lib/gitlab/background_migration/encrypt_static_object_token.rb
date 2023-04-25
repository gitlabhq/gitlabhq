# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Populates "static_object_token_encrypted" field with encrypted versions
    # of values from "static_object_token" field
    class EncryptStaticObjectToken
      # rubocop:disable Style/Documentation
      class User < ActiveRecord::Base
        include ::EachBatch
        self.table_name = 'users'
        scope :with_static_object_token, -> { where.not(static_object_token: nil) }
        scope :without_static_object_token_encrypted, -> { where(static_object_token_encrypted: nil) }
      end
      # rubocop:enable Style/Documentation

      BATCH_SIZE = 100

      def perform(start_id, end_id)
        ranged_query = User
          .where(id: start_id..end_id)
          .with_static_object_token
          .without_static_object_token_encrypted

        ranged_query.each_batch(of: BATCH_SIZE) do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          batch_query = User.unscoped
                          .where(id: first..last)
                          .with_static_object_token
                          .without_static_object_token_encrypted

          user_tokens = batch_query.pluck(:id, :static_object_token)

          user_encrypted_tokens = user_tokens.map do |(id, plaintext_token)|
            next if plaintext_token.blank?

            [id, Gitlab::CryptoHelper.aes256_gcm_encrypt(plaintext_token)]
          end

          encrypted_tokens_sql = user_encrypted_tokens.compact.map { |(id, token)| "(#{id}, '#{token}')" }.join(',')

          next unless user_encrypted_tokens.present?

          User.connection.execute(<<~SQL)
              WITH cte(cte_id, cte_token) AS #{::Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
                SELECT *
                FROM (VALUES #{encrypted_tokens_sql}) AS t (id, token)
              )
              UPDATE #{User.table_name}
              SET static_object_token_encrypted = cte_token
              FROM cte
              WHERE cte_id = id
          SQL
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
