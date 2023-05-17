# frozen_string_literal: true

module Gitlab
  module Ci
    module Input
      module Arguments
        ##
        # Input::Arguments::Options class represents user-provided input argument that is an enum, and is only valid
        # when the value provided is listed as an acceptable one.
        #
        class Options < Input::Arguments::Base
          ##
          # An empty value is valid if it is allowlisted:
          #
          # ```yaml
          # inputs:
          #   run:
          #     - ""
          #     - tests
          #
          # with:
          #   run: ""
          # ```
          #
          # The configuration above will return an empty value.
          #
          def validate!
            return error('argument specification invalid') unless options.is_a?(Array)
            return error('options argument empty') if options.empty?

            if !value.nil?
              error("argument value #{value} not allowlisted") unless options.include?(value)
            else
              error('argument not provided')
            end
          end

          def to_value
            value
          end

          def options
            spec[:options]
          end

          def self.matches?(spec)
            return false unless spec.is_a?(Hash)

            spec.count == 1 && spec.each_key.first == :options
          end
        end
      end
    end
  end
end
