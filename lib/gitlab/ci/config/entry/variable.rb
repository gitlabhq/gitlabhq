# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a CI/CD variable.
        #
        class Variable < ::Gitlab::Config::Entry::Simplifiable
          strategy :SimpleVariable, if: -> (config) { SimpleVariable.applies_to?(config) }
          strategy :ComplexVariable, if: -> (config) { ComplexVariable.applies_to?(config) }

          class SimpleVariable < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            class << self
              def applies_to?(config)
                Gitlab::Config::Entry::Validators::AlphanumericValidator.validate(config)
              end
            end

            validations do
              validates :key, alphanumeric: true
              validates :config, alphanumeric: true
            end

            def value
              @config.to_s
            end

            def value_with_data
              { value: @config.to_s }
            end
          end

          class ComplexVariable < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            class << self
              def applies_to?(config)
                config.is_a?(Hash)
              end
            end

            validations do
              validates :key, alphanumeric: true
              validates :config_value, alphanumeric: true, allow_nil: false, if: :config_value_defined?
              validates :config_description, alphanumeric: true, allow_nil: false, if: :config_description_defined?

              validate do
                allowed_value_data = Array(opt(:allowed_value_data))

                if allowed_value_data.any?
                  extra_keys = config.keys - allowed_value_data

                  errors.add(:config, "uses invalid data keys: #{extra_keys.join(', ')}") if extra_keys.present?
                else
                  errors.add(:config, "must be a string")
                end
              end
            end

            def value
              config_value.to_s
            end

            def value_with_data
              { value: value, description: config_description }.compact
            end

            def config_value
              @config[:value]
            end

            def config_description
              @config[:description]
            end

            def config_value_defined?
              config.key?(:value)
            end

            def config_description_defined?
              config.key?(:description)
            end
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
            def errors
              ["variable definition must be either a string or a hash"]
            end
          end
        end
      end
    end
  end
end
