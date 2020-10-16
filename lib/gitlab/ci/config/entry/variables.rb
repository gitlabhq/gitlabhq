# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents environment variables.
        #
        class Variables < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_VALUE_DATA = %i[value description].freeze

          validations do
            validates :config, variables: { allowed_value_data: ALLOWED_VALUE_DATA }
          end

          def value
            Hash[@config.map { |key, value| [key.to_s, expand_value(value)[:value]] }]
          end

          def self.default(**)
            {}
          end

          def value_with_data
            Hash[@config.map { |key, value| [key.to_s, expand_value(value)] }]
          end

          private

          def expand_value(value)
            if value.is_a?(Hash)
              { value: value[:value].to_s, description: value[:description] }
            else
              { value: value.to_s, description: nil }
            end
          end
        end
      end
    end
  end
end
