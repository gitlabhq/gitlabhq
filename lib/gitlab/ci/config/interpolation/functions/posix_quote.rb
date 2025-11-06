# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        module Functions
          class PosixQuote < Base
            def self.function_expression_pattern
              /^#{name}$/
            end

            def self.name
              'posix_quote'
            end

            def execute(input_value)
              unless input_value.is_a?(String)
                error("invalid input type: #{self.class.name} can only be used with string inputs")
                return
              end

              Shellwords.shellescape(input_value)
            end
          end
        end
      end
    end
  end
end
