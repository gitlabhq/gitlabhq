# frozen_string_literal: true

module Integrations
  module BaseDataFields
    extend ActiveSupport::Concern

    included do
      belongs_to :integration, inverse_of: self.table_name.to_sym, foreign_key: :integration_id

      validates :integration, presence: true
    end

    class_methods do
      def encryption_options
        {
          key: Settings.attr_encrypted_db_key_base_32,
          encode: true,
          mode: :per_attribute_iv,
          algorithm: 'aes-256-gcm'
        }
      end
    end

    def activated?
      !!integration&.activated?
    end

    def to_database_hash
      as_json(
        only: self.class.column_names
      ).except('id', 'service_id', 'integration_id', 'created_at', 'updated_at')
    end
  end
end
