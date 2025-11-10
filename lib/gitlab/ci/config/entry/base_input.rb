# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Common validations and behavior for input definitions in CI configuration.
        # Used by JobInput (job-level inputs) and Header::Input (spec-level inputs).
        module BaseInput
          extend ActiveSupport::Concern

          COMMON_ALLOWED_KEYS = %i[default description options regex type].freeze
          ALLOWED_OPTIONS_LIMIT = 50

          included do
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            attributes :default, :description, :options, :regex, :type, prefix: :input

            validations do
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
              end
            end
          end

          def value
            config
          end
        end
      end
    end
  end
end
