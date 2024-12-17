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

      scope :by_key, ->(key) { where(key: key) }
      scope :order_key_asc, -> { reorder(key: :asc) }
      scope :order_key_desc, -> { reorder(key: :desc) }

      attr_encrypted :value,
        mode: :per_attribute_iv_and_salt,
        insecure_mode: true,
        key: Settings.attr_encrypted_db_key_base,
        algorithm: 'aes-256-cbc'

      def key=(new_key)
        super(new_key.to_s.strip)
      end
    end

    class_methods do
      def order_by(method)
        case method.to_s
        when 'key_asc' then order_key_asc
        when 'key_desc' then order_key_desc
        else all
        end
      end
    end

    def to_hash_variable
      var_cache_key = to_hash_variable_cache_key

      return uncached_hash_variable unless var_cache_key

      ::Gitlab::SafeRequestStore.fetch(var_cache_key) { uncached_hash_variable }
    end

    private

    def uncached_hash_variable
      { key: key, value: value, public: false, file: file? }
    end

    def to_hash_variable_cache_key
      return unless persisted?

      variable_id = read_attribute(self.class.primary_key)
      "#{self.class}#to_hash_variable:#{variable_id}:#{key}"
    end
  end
end
