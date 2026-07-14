# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        module Functions
          class Split < Base
            def self.function_expression_pattern
              /^split\('(?<separator>[^']*)'\)$/
            end

            def self.name
              'split'
            end

            def execute(input_value)
              unless input_value.is_a?(String)
                return error("invalid input type: split can only be used with string inputs")
              end

              return error("invalid argument: separator cannot be empty") if separator.empty?

              input_value.split(separator).map(&:strip).reject(&:empty?)
            end

            private

            def separator
              function_args[:separator]
            end
          end
        end
      end
    end
  end
end
