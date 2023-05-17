# frozen_string_literal: true

module Gitlab
  module Ci
    module Input
      module Arguments
        ##
        # Input::Arguments::Base is a common abstraction for input arguments:
        #   - required
        #   - optional
        #   - with a default value
        #
        class Base
          attr_reader :key, :value, :spec, :errors

          ArgumentNotValidError = Class.new(StandardError)

          def initialize(key, spec, value)
            @key = key      # hash key / argument name
            @value = value  # user-provided value
            @spec = spec    # configured specification
            @errors = []

            unless value.is_a?(String) || value.nil? # rubocop:disable Style/IfUnlessModifier
              @errors.push("unsupported value in input argument `#{key}`")
            end

            validate!
          end

          def valid?
            @errors.none?
          end

          def validate!
            raise NotImplementedError
          end

          def to_value
            raise NotImplementedError
          end

          def to_hash
            raise ArgumentNotValidError unless valid?

            @output ||= { key => to_value }
          end

          def self.matches?(spec)
            raise NotImplementedError
          end

          private

          def error(message)
            @errors.push("`#{@key}` input: #{message}")
          end
        end
      end
    end
  end
end
