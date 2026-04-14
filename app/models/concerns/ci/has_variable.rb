# frozen_string_literal: true

module Ci
  module HasVariable
    extend ActiveSupport::Concern

    # The following line is included in the models that include this concern.
    # It doesn't work in the concern itself, so is put here only for reference.
    # ignore_columns :value, remove_with: '19.1', remove_after: '2026-05-21' # https://gitlab.com/gitlab-org/gitlab/-/work_items/592747
    # It is _not_ included in ee/app/models/dast/site_profile_secret_variable
    # as that model does not include the column in its table.

    included do
      include Gitlab::EncryptedAttribute

      enum :variable_type, Enums::Ci::Variable::TYPES

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
        key: :db_key_base,
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
