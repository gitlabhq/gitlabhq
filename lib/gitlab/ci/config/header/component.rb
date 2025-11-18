# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Header
        ##
        # Component context configuration used for interpolation with the CI configuration.
        #
        # This class defines the available component context information that can be used
        # in CI configuration interpolation.
        #
        class Component < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_VALUES = %i[name sha version reference].freeze
          ALLOWED_VALUES_TO_S = ALLOWED_VALUES.map(&:to_s).freeze

          validations do
            validates :config, type: Array, array_of_strings: true, allowed_array_values: { in: ALLOWED_VALUES_TO_S }
          end

          def value
            return [] unless valid?

            config.uniq.map(&:to_sym)
          end
        end
      end
    end
  end
end
