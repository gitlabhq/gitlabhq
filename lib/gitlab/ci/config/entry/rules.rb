# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, presence: true
            validates :config, type: Array
          end

          def value
            if ::Feature.enabled?(:ci_value_change_for_processable_and_rules_entry)
              # `flatten` is needed to make it work with nested `!reference`
              [super].flatten
            else
              [@config].flatten
            end
          end

          def composable_class
            Entry::Rules::Rule
          end
        end
      end
    end
  end
end
