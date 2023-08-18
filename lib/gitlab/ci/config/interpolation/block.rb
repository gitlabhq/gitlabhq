# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        ##
        # This class represents an interpolation block. The format supported is:
        # $[[ <access> | <function1> | <function2> | ... <functionN> ]]
        #
        # <access> specifies the value to retrieve (e.g. `inputs.key`).
        # <function> can be optionally provided with or without arguments to
        # manipulate the access value. Functions are evaluated in the order
        # they are presented.
        class Block
          PREFIX = '$[['
          PATTERN = /(?<block>\$\[\[\s*(?<data>.*?)\s*\]\])/
          MAX_FUNCTIONS = 3

          attr_reader :block, :data, :ctx, :errors

          def initialize(block, data, ctx)
            @block = block
            @data = data
            @ctx = ctx
            @errors = []
            @value = nil

            evaluate!
          end

          def valid?
            errors.none?
          end

          def content
            data
          end

          def value
            raise ArgumentError, 'block invalid' unless valid?

            @value
          end

          def self.match(data)
            return data unless data.is_a?(String) && data.include?(PREFIX)

            data.gsub(PATTERN) do
              yield ::Regexp.last_match(1), ::Regexp.last_match(2)
            end
          end

          private

          # We expect the block data to be a string with one or more entities delimited by pipes:
          # <access> | <function1> | <function2> | ... <functionN>
          def evaluate!
            data_access, *functions = data.split('|').map(&:strip)
            access = Interpolation::Access.new(data_access, ctx)

            return @errors.concat(access.errors) unless access.valid?
            return @errors.push('too many functions in interpolation block') if functions.count > MAX_FUNCTIONS

            result = Interpolation::FunctionsStack.new(functions).evaluate(access.value)

            if result.success?
              @value = result.value
            else
              @errors.concat(result.errors)
            end
          end
        end
      end
    end
  end
end
