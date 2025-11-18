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
          MAX_FUNCTIONS = 3
          SKIP_INTERPOLATION_CONTEXTS = %w[matrix].freeze

          attr_reader :data, :ctx, :errors

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

          def length
            block.length
          end

          def to_s
            block
          end

          private

          attr_reader :block

          # We expect the block data to be a string with one or more entities delimited by pipes:
          # <access> | <function1> | <function2> | ... <functionN>
          def evaluate!
            data_access, *functions = data.split('|').map(&:strip)

            if skip_interpolation?(data_access)
              @value = block
              return
            end

            access = Interpolation::Access.new(data_access, ctx)

            return @errors.concat(access.errors) unless access.valid?
            return @errors.push('too many functions in interpolation block') if functions.count > MAX_FUNCTIONS

            result = Interpolation::FunctionsStack.new(functions, ctx).evaluate(access.value)

            if result.success?
              @value = result.value
            else
              @errors.concat(result.errors)
            end
          end

          def skip_interpolation?(data_access)
            context_name = data_access.split('.').first

            SKIP_INTERPOLATION_CONTEXTS.include?(context_name)
          end
        end
      end
    end
  end
end
