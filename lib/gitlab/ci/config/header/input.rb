# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        ##
        # Input parameter used for interpolation with the CI configuration.
        #
        class Input < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[default description options regex type rules].freeze
          ALLOWED_OPTIONS_LIMIT = 50

          attributes ALLOWED_KEYS, prefix: :input

          entry :rules, Gitlab::Ci::Config::Header::Input::Rules,
            description: 'Conditional options and defaults for the input.',
            inherit: true

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :config, mutually_exclusive_keys: %i[rules options]
            validates :config, mutually_exclusive_keys: %i[rules default]
            validates :key, alphanumeric: true
            validates :input_description, alphanumeric: true, allow_nil: true
            validates :input_regex, type: String, allow_nil: true
            validates :input_type, allow_nil: true,
              allowed_values: ::Ci::Inputs::Builder.input_types
            validates :input_options, type: Array, allow_nil: true

            validate do
              if input_options&.size.to_i > ALLOWED_OPTIONS_LIMIT
                errors.add(:config, "cannot define more than #{ALLOWED_OPTIONS_LIMIT} options")
              end

              if config.is_a?(Hash) && config.key?(:rules) && !Feature.enabled?(:ci_dynamic_pipeline_inputs,
                @metadata&.[](:project))
                errors.add(:rules, "is not yet supported")
              end
            end
          end

          def input_rules
            return unless config.is_a?(Hash) && config.key?(:rules)

            config[:rules]
          end

          def value
            config
          end
        end
      end
    end
  end
end
