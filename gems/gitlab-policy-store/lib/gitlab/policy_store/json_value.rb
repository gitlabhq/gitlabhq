# frozen_string_literal: true

module Gitlab
  module PolicyStore
    # A persistence layer stringifies on the way in whatever it was handed: jsonb
    # returns string keys and string values, and ActiveRecord casts a Symbol on a
    # text column. The adapters only agree if the component does the same.
    module JsonValue
      def self.deep_stringify(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, nested), stringified| stringified[key.to_s] = deep_stringify(nested) }
        when Array then value.map { |item| deep_stringify(item) }
        when Symbol then value.to_s
        else value
        end
      end
    end
  end
end
