# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of the pull policies of an image.
        #
        class PullPolicy < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_POLICIES = %w[always never if-not-present].freeze

          validations do
            validates :config, array_of_strings_or_string: true
            validates :config,
              allowed_array_values: { in: ALLOWED_POLICIES },
              presence: true,
              if: :array?
            validates :config,
              inclusion: { in: ALLOWED_POLICIES },
              if: :string?
          end

          def value
            # We either return an array with policies or nothing
            Array(@config).presence
          end
        end
      end
    end
  end
end
