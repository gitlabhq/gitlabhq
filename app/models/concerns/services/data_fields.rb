# frozen_string_literal: true

module Services
  module DataFields
    extend ActiveSupport::Concern

    included do
      belongs_to :integration, inverse_of: self.name.underscore.to_sym, foreign_key: :service_id

      delegate :activated?, to: :integration, allow_nil: true

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
  end
end
