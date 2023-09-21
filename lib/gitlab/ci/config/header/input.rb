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

          attributes :default, :description, :type, prefix: :input

          validations do
            validates :config, type: Hash, allowed_keys: [:default, :type, :description]
            validates :key, alphanumeric: true
            validates :input_default, alphanumeric: true, allow_nil: true
            validates :input_type, allow_nil: true, allowed_values: Interpolation::Inputs.input_types
            validates :input_description, alphanumeric: true, allow_nil: true
          end
        end
      end
    end
  end
end
