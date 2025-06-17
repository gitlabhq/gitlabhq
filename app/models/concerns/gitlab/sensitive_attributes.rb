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
          attributes.concat attr_encrypted_encrypted_attributes.values.map { |v| v[:attribute] } # rubocop:disable Rails/Pluck -- Not a ActiveRecord object
          attributes.concat attr_encrypted_encrypted_attributes.values.map { |v| :"#{v[:attribute]}_iv" }
        end

        if respond_to?(:token_authenticatable_sensitive_fields)
          attributes.concat(token_authenticatable_sensitive_fields)
        end

        attributes
      end
    end
  end
end
