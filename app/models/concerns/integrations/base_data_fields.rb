# frozen_string_literal: true

module Integrations
  module BaseDataFields
    extend ActiveSupport::Concern

    included do
      belongs_to :integration, inverse_of: self.table_name.to_sym, foreign_key: :integration_id, optional: true

      belongs_to :instance_integration,
        inverse_of: self.table_name.to_sym,
        foreign_key: :instance_integration_id,
        class_name: 'Integrations::Instance::Integration',
        optional: true

      validates :integration, absence: true, if: :instance_integration
      validates :instance_integration, absence: true, if: :integration
      validate :validate_mutual_exclusion
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
      ).except('id', 'service_id', 'integration_id', 'created_at', 'updated_at', 'instance_integration_id')
    end

    private

    def validate_mutual_exclusion
      return if integration.present? ^ instance_integration.present?

      errors.add(:base, :blank, message: 'one of integration or instance_integration must be present')
    end
  end
end
