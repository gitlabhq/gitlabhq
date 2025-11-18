# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        ##
        # Input parameter used for interpolation with the CI configuration.
        #
        class Input < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::BaseInput
          include ::Gitlab::Config::Entry::Configurable

          ADDITIONAL_ALLOWED_KEYS = %i[rules].freeze
          ALLOWED_KEYS = (COMMON_ALLOWED_KEYS + ADDITIONAL_ALLOWED_KEYS).freeze

          entry :rules, Gitlab::Ci::Config::Header::Input::Rules,
            description: 'Conditional options and defaults for the input.',
            inherit: true

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :config, mutually_exclusive_keys: %i[rules options]
            validates :config, mutually_exclusive_keys: %i[rules default]

            validate do
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
        end
      end
    end
  end
end
