# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a script.
        #
        class Script < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, nested_array_of_strings: true
          end

          def value
            config.flatten(1)
          end
        end
      end
    end
  end
end
