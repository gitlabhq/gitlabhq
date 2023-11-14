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

          ALLOWED_KEYS = %i[default description options regex type].freeze
          ALLOWED_OPTIONS_LIMIT = 50

          attributes ALLOWED_KEYS, prefix: :input

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :key, alphanumeric: true
            validates :input_description, alphanumeric: true, allow_nil: true
            validates :input_regex, type: String, allow_nil: true
            validates :input_type, allow_nil: true, allowed_values: Interpolation::Inputs.input_types
            validates :input_options, type: Array, allow_nil: true

            validate do
              if input_options&.size.to_i > ALLOWED_OPTIONS_LIMIT
                errors.add(:config, "cannot define more than #{ALLOWED_OPTIONS_LIMIT} options")
              end
            end
          end
        end
      end
    end
  end
end
