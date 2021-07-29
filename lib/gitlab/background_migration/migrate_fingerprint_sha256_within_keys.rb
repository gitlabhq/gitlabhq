# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is responsible to update all sha256 fingerprints within the keys table
    class MigrateFingerprintSha256WithinKeys
      # Temporary AR table for keys
      class Key < ActiveRecord::Base
        include EachBatch

        self.table_name = 'keys'
        self.inheritance_column = :_type_disabled
      end

      TEMP_TABLE = 'tmp_fingerprint_sha256_migration'

      def perform(start_id, stop_id)
        ActiveRecord::Base.transaction do
          execute(<<~SQL)
            CREATE TEMPORARY TABLE #{TEMP_TABLE}
              (id bigint primary key, fingerprint_sha256 bytea not null)
              ON COMMIT DROP
          SQL

          fingerprints = []
          Key.where(id: start_id..stop_id, fingerprint_sha256: nil).find_each do |regular_key|
            if fingerprint = generate_ssh_public_key(regular_key.key)
              bytea = ActiveRecord::Base.connection.escape_bytea(Base64.decode64(fingerprint))

              fingerprints << {
                id: regular_key.id,
                fingerprint_sha256: bytea
              }
            end
          end

          Gitlab::Database.main.bulk_insert(TEMP_TABLE, fingerprints) # rubocop:disable Gitlab/BulkInsert

          execute("ANALYZE #{TEMP_TABLE}")

          execute(<<~SQL)
            UPDATE keys
              SET fingerprint_sha256 = t.fingerprint_sha256
              FROM #{TEMP_TABLE} t
              WHERE keys.id = t.id
          SQL
        end
      end

      private

      def generate_ssh_public_key(regular_key)
        Gitlab::SSHPublicKey.new(regular_key).fingerprint("SHA256")&.gsub("SHA256:", "")
      end

      def execute(query)
        ActiveRecord::Base.connection.execute(query)
      end
    end
  end
end
