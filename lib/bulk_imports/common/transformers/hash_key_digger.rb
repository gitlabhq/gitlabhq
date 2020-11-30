# frozen_string_literal: true

module BulkImports
  module Common
    module Transformers
      class HashKeyDigger
        def initialize(options = {})
          @key_path = options[:key_path]
        end

        def transform(_, data)
          raise ArgumentError, "Given data must be a Hash" unless data.is_a?(Hash)

          data.dig(*Array.wrap(key_path))
        end

        private

        attr_reader :key_path
      end
    end
  end
end
