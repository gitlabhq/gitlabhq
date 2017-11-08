# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      module ToHash
        # Converts the current representation to a Hash. The keys of this Hash
        # will be Symbols.
        def to_hash
          hash = {}

          attributes.each do |key, value|
            hash[key] = convert_value_for_to_hash(value)
          end

          hash
        end

        def convert_value_for_to_hash(value)
          if value.is_a?(Array)
            value.map { |v| convert_value_for_to_hash(v) }
          elsif value.respond_to?(:to_hash)
            value.to_hash
          else
            value
          end
        end
      end
    end
  end
end
