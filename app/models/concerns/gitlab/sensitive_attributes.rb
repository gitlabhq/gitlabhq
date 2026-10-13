# frozen_string_literal: true

module Gitlab
  module SensitiveAttributes
    extend ActiveSupport::Concern

    class_methods do
      def sensitive_attributes
        attributes = []

        if respond_to?(:attr_encrypted_encrypted_attributes)
          # Per https://github.com/attr-encrypted/attr_encrypted/blob/c2aa160c2327f2613fbca913e9fd20bce6e98880/lib/attr_encrypted.rb#L413
          attributes.concat attr_encrypted_encrypted_attributes.keys
          attributes.concat attr_encrypted_encrypted_attributes.values.map { |v| v[:attribute] }
          attributes.concat attr_encrypted_encrypted_attributes.values.map { |v| :"#{v[:attribute]}_iv" }
        end

        # Rails native encryption, which is not covered by attr_encrypted above.
        # Every AR model responds to this, so the guard is only for non-AR
        # classes that include the concern. `encrypted_attributes` is nil until
        # `encrypts` is called, and a Set of Symbols after.
        #
        # This list also drives audit log redaction in
        # ee/lib/audit_events/changes.rb, not only serialization.
        attributes.concat(encrypted_attributes.to_a) if respond_to?(:encrypted_attributes)

        if respond_to?(:token_authenticatable_sensitive_fields)
          attributes.concat(token_authenticatable_sensitive_fields)
        end

        attributes
      end
    end
  end
end
