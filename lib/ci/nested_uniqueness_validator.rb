module Ci
  module NestedUniquenessValidator
    class << self
      def duplicated?(nested_attributes, unique_key)
        return false unless nested_attributes.is_a?(Array)

        nested_attributes.map { |v| v[unique_key] }.uniq.length != nested_attributes.length
      end
    end
  end
end
