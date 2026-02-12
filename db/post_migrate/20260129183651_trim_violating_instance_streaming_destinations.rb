# frozen_string_literal: true

class TrimViolatingInstanceStreamingDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  PLAINTEXT_LIMIT = 4096
  ENCRYPTED_LIMIT = PLAINTEXT_LIMIT + 16
  MAX_NAME_LENGTH = 72
  NAME_PREFIX = "[INVALID] "
  BATCH_SIZE = 50

  class InstanceExternalStreamingDestination < MigrationRecord
    include EachBatch
    include ::Gitlab::EncryptedAttribute

    self.table_name = 'audit_events_instance_external_streaming_destinations'

    attr_encrypted :secret_token,
      mode: :per_attribute_iv,
      key: :db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false
  end

  def up
    InstanceExternalStreamingDestination
      .where("octet_length(encrypted_secret_token) > ?", ENCRYPTED_LIMIT)
      .each_batch(of: BATCH_SIZE) do |batch|
        updates = []

        batch.each do |record|
          plaintext = record.secret_token
          next unless plaintext && plaintext.length > PLAINTEXT_LIMIT

          record.secret_token = plaintext[0, PLAINTEXT_LIMIT]

          updates << {
            id: record.id,
            encrypted_secret_token: record.encrypted_secret_token,
            encrypted_secret_token_iv: record.encrypted_secret_token_iv,
            name: "#{NAME_PREFIX}#{record.name}"[0, MAX_NAME_LENGTH]
          }
        end

        next if updates.empty?

        values = updates.map do |row|
          token_hex = "decode('#{row[:encrypted_secret_token].unpack1('H*')}', 'hex')"
          iv_hex = "decode('#{row[:encrypted_secret_token_iv].unpack1('H*')}', 'hex')"

          "(#{row[:id]}, #{token_hex}, #{iv_hex}, #{connection.quote(row[:name])})"
        end.join(",\n  ")

        sql = <<~SQL
          UPDATE audit_events_instance_external_streaming_destinations
          SET
            encrypted_secret_token = t.encrypted_secret_token,
            encrypted_secret_token_iv = t.encrypted_secret_token_iv,
            name = t.name,
            active = false
          FROM (VALUES #{values}) AS t(id, encrypted_secret_token, encrypted_secret_token_iv, name)
          WHERE audit_events_instance_external_streaming_destinations.id = t.id
        SQL

        connection.execute(sql)
      end
  end

  def down
    # Cannot restore original tokens
  end
end
