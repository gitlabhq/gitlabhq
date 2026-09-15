# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module EnumeratedAttributeValidation
      private

      def validate_enumerated_attributes!(attributes, vocabularies)
        vocabularies.each do |attribute, permitted|
          value = attributes[attribute]
          next if value.nil? || permitted.include?(value)

          raise PolicyStore::ValidationError,
            "#{attribute} must be one of: #{permitted.join(', ')} (got #{value.inspect})"
        end
      end
    end
  end
end
