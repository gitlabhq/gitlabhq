# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a job script.
        #
        class Commands < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          MAX_NESTING_LEVEL = 10

          validations do
            validates :config, string_or_nested_array_of_strings: { max_level: MAX_NESTING_LEVEL }
          end

          def value
            Array(@config).flatten
          end
        end
      end
    end
  end
end
