# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a list of include.
        #
        class Includes < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, array_or_string: true

            validate do
              next unless opt(:max_size)
              next unless config.is_a?(Array)

              if config.size > opt(:max_size)
                errors.add(:config, "is too long (maximum is #{opt(:max_size)})")
              end
            end
          end

          def composable_class
            Entry::Include
          end
        end
      end
    end
  end
end
