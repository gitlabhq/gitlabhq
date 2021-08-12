# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Include
          class Rules < ::Gitlab::Config::Entry::ComposableArray
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, presence: true
              validates :config, type: Array
            end

            def value
              @config
            end

            def composable_class
              Entry::Include::Rules::Rule
            end
          end
        end
      end
    end
  end
end
