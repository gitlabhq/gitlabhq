# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a CI/CD variable.
        #
        class Variable < ::Gitlab::Config::Entry::Simplifiable
          strategy :SimpleVariable, if: ->(config) { SimpleVariable.applies_to?(config) }
          strategy :ComplexVariable, if: ->(config) { ComplexVariable.applies_to?(config) }

          class SimpleVariable < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            class << self
              def applies_to?(config)
                Gitlab::Config::Entry::Validators::ScalarValidator.validate(config)
              end
            end

            validations do
              validates :key, alphanumeric: true
              validates :config, scalar: true
            end

            def value
              @config.to_s
            end

            def value_with_data
              { value: @config.to_s }
            end

            def value_with_prefill_data
              value_with_data
            end
          end

          class ComplexVariable < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            class << self
              def applies_to?(config)
                config.is_a?(Hash)
              end
            end

            attributes :value, :description, :expand, :options, prefix: :config

            validations do
              validates :key, alphanumeric: true
              validates :config_value, scalar: true, allow_nil: true
              validates :config_description, alphanumeric: true, allow_nil: true
              validates :config_expand, boolean: true, allow_nil: true
              validates :config_options, array_of_strings: true, allow_nil: true

              validate do
                allowed_value_data = Array(opt(:allowed_value_data))

                if allowed_value_data.any?
                  extra_keys = config.keys - allowed_value_data

                  errors.add(:config, "uses invalid data keys: #{extra_keys.join(', ')}") if extra_keys.present?
                else
                  errors.add(:config, "must be a string")
                end

                if config_options.present? && config_options.exclude?(config_value)
                  errors.add(:config, 'value must be present in options')
                end
              end
            end

            def value
              # Needed since the `Entry::Node` provides `value` (which is current hash)
              config_value.to_s
            end

            def value_with_data
              {
                value: config_value.to_s,
                raw: (!config_expand if has_config_expand?)
              }.compact
            end

            def value_with_prefill_data
              value_with_data.merge(
                description: config_description,
                options: config_options
              ).compact
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
