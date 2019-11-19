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

          validations do
            validates :config, string_or_nested_array_of_strings: true
          end

          def value
            Array(@config).flatten(1)
          end
        end
      end
    end
  end
end
