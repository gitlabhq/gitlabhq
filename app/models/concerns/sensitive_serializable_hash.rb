# frozen_string_literal: true

module SensitiveSerializableHash
  extend ActiveSupport::Concern

  included do
    class_attribute :attributes_exempt_from_serializable_hash, default: []
  end

  class_methods do
    def prevent_from_serialization(*keys)
      self.attributes_exempt_from_serializable_hash ||= []
      self.attributes_exempt_from_serializable_hash += keys
    end
  end

  # Override serializable_hash to exclude sensitive attributes by default
  #
  # In general, prefer NOT to use serializable_hash / to_json / as_json in favor
  # of serializers / entities instead which has an allowlist of attributes
  def serializable_hash(options = nil)
    options = options.try(:dup) || {}
    options[:except] = Array(options[:except]).dup

    options[:except].concat self.class.attributes_exempt_from_serializable_hash

    if self.class.respond_to?(:attr_encrypted_attributes)
      options[:except].concat self.class.attr_encrypted_attributes.keys

      # Per https://github.com/attr-encrypted/attr_encrypted/blob/a96693e9a2a25f4f910bf915e29b0f364f277032/lib/attr_encrypted.rb#L413
      options[:except].concat self.class.attr_encrypted_attributes.values.map { |v| v[:attribute] }
      options[:except].concat self.class.attr_encrypted_attributes.values.map { |v| "#{v[:attribute]}_iv" }
    end

    super(options)
  end
end
