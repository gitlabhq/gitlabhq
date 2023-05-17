# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates the integration.properties column from plaintext to encrypted text.
    class EncryptIntegrationProperties
      # The Integration model, with just the relevant bits.
      class Integration < ActiveRecord::Base
        include EachBatch

        ALGORITHM = 'aes-256-gcm'

        self.table_name = 'integrations'
        self.inheritance_column = :_type_disabled

        scope :with_properties, -> { where.not(properties: nil) }
        scope :not_already_encrypted, -> { where(encrypted_properties: nil) }
        scope :for_batch, ->(range) { where(id: range) }

        attr_encrypted :encrypted_properties_tmp,
          attribute: :encrypted_properties,
          mode: :per_attribute_iv,
          key: ::Settings.attr_encrypted_db_key_base_32,
          algorithm: ALGORITHM,
          marshal: true,
          marshaler: ::Gitlab::Json,
          encode: false,
          encode_iv: false

        # See 'Integration#reencrypt_properties'
        def encrypt_properties
          data = ::Gitlab::Json.parse(properties)
          iv = generate_iv(ALGORITHM)
          ep = self.class.attr_encrypt(:encrypted_properties_tmp, data, { iv: iv })

          [ep, iv]
        end
      end

      def perform(start_id, stop_id)
        batch_query = Integration.with_properties.not_already_encrypted.for_batch(start_id..stop_id)
        encrypt_batch(batch_query)
        mark_job_as_succeeded(start_id, stop_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end

      # represent binary string as a PSQL binary literal:
      # https://www.postgresql.org/docs/9.4/datatype-binary.html
      def bytea(value)
        "'\\x#{value.unpack1('H*')}'::bytea"
      end

      def encrypt_batch(batch_query)
        values = batch_query.select(:id, :properties).map do |record|
          encrypted_properties, encrypted_properties_iv = record.encrypt_properties
          "(#{record.id}, #{bytea(encrypted_properties)}, #{bytea(encrypted_properties_iv)})"
        end

        return if values.empty?

        Integration.connection.execute(<<~SQL.squish)
          WITH cte(cte_id, cte_encrypted_properties, cte_encrypted_properties_iv)
            AS #{::Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            SELECT *
            FROM (VALUES #{values.join(',')}) AS t (id, encrypted_properties, encrypted_properties_iv)
          )
          UPDATE #{Integration.table_name}
          SET encrypted_properties = cte_encrypted_properties
            , encrypted_properties_iv = cte_encrypted_properties_iv
          FROM cte
          WHERE cte_id = id
        SQL
      end
    end
  end
end
