# frozen_string_literal: true

module Ci
  module HasVariable
    extend ActiveSupport::Concern

    included do
      enum variable_type: {
        env_var: 1,
        file: 2
      }

      validates :key,
        presence: true,
        length: { maximum: 255 },
        format: { with: /\A[a-zA-Z0-9_]+\z/,
                  message: "can contain only letters, digits and '_'." }

      scope :by_key, -> (key) { where(key: key) }
      scope :order_key_asc, -> { reorder(key: :asc) }

      attr_encrypted :value,
        mode: :per_attribute_iv_and_salt,
        insecure_mode: true,
        key: Settings.attr_encrypted_db_key_base,
        algorithm: 'aes-256-cbc'

      def key=(new_key)
        super(new_key.to_s.strip)
      end
    end

    def to_runner_variable
      { key: key, value: value, public: false, file: file? }
    end
  end
end
