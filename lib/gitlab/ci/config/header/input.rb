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

          attributes :default, prefix: :input

          validations do
            validates :config, type: Hash, allowed_keys: [:default]
            validates :key, alphanumeric: true
            validates :input_default, alphanumeric: true, allow_nil: true
          end
        end
      end
    end
  end
end
