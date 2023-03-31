# frozen_string_literal: true

module Gitlab
  module Ci
    module Interpolation
      ##
      # Interpolation::Context is a class that represents the data that can be used when performing string interpolation
      # on a CI configuration.
      #
      class Context
        ContextTooComplexError = Class.new(StandardError)
        NotSymbolizedContextError = Class.new(StandardError)

        MAX_DEPTH = 3

        def initialize(hash)
          @context = hash

          raise ContextTooComplexError if depth > MAX_DEPTH
        end

        def valid?
          errors.none?
        end

        ##
        # This method is here because `Context` will be responsible for validating specs, inputs and defaults.
        #
        def errors
          []
        end

        def depth
          deep_depth(@context)
        end

        def fetch(field)
          @context.fetch(field)
        end

        def key?(name)
          @context.key?(name)
        end

        def to_h
          @context.to_h
        end

        private

        def deep_depth(context, depth = 0)
          values = context.values.map do |value|
            if value.is_a?(Hash)
              deep_depth(value, depth + 1)
            else
              depth + 1
            end
          end

          values.max.to_i
        end

        def self.fabricate(context)
          case context
          when Hash
            new(context)
          when Interpolation::Context
            context
          else
            raise ArgumentError, 'unknown interpolation context'
          end
        end
      end
    end
  end
end
