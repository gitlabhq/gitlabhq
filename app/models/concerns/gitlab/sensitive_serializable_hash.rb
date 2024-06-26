# frozen_string_literal: true

module Gitlab
  module SensitiveSerializableHash
    extend ActiveSupport::Concern

    include SensitiveAttributes

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

      options[:except].concat self.class.sensitive_attributes

      super(options)
    end
  end
end
