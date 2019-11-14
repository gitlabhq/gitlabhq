# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an array of file paths.
        #
        class Files < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, array_of_strings: true
            validates :config, length: {
              minimum: 1,
              maximum: 2,
              too_short: 'requires at least %{count} item',
              too_long: 'has too many items (maximum is %{count})'
            }
          end
        end
      end
    end
  end
end
