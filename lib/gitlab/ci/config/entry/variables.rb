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
            validates :config, variables: { allowed_value_data: ALLOWED_VALUE_DATA }, if: :use_value_data?
            validates :config, variables: true, unless: :use_value_data?
          end

          def value
            @config.to_h do |key, data|
              [key.to_s, expand_data(data)[:value]]
            end
          end

          def self.default(**)
            {}
          end

          def value_with_data
            @config.to_h do |key, data|
              [key.to_s, expand_data(data)]
            end
          end

          def use_value_data?
            opt(:use_value_data)
          end

          private

          def expand_data(data)
            if data.is_a?(Hash)
              { value: data[:value].to_s, description: data[:description] }.compact
            else
              { value: data.to_s }
            end
          end
        end
      end
    end
  end
end
