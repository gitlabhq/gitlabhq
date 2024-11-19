# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'
require 'delegate'

require_relative 'flaky_example'

module Gitlab
  module RspecFlaky
    class FlakyExamplesCollection < SimpleDelegator
      def initialize(collection = {})
        raise ArgumentError, "`collection` must be a Hash, #{collection.class} given!" unless collection.is_a?(Hash)

        collection_of_flaky_examples =
          collection.map do |uid, example|
            [
              uid,
              FlakyExample.new(example.to_h.symbolize_keys)
            ]
          end

        super(Hash[collection_of_flaky_examples])
      end

      def to_h
        transform_values(&:to_h).deep_symbolize_keys
      end

      def -(other)
        raise ArgumentError, "`other` must respond to `#key?`, #{other.class} does not!" unless other.respond_to?(:key)

        self.class.new(reject { |uid, _| other.key?(uid) })
      end
    end
  end
end
