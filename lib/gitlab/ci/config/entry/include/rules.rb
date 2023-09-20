# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Include
          ##
          # Include rules are validated separately from all other entries. This
          # is because included files are expanded before `@root.compose!` runs
          # in Ci::Config. As such, this class is directly instantiated and
          # composed in lib/gitlab/ci/config/external/rules.rb.
          #
          class Rules < ::Gitlab::Config::Entry::ComposableArray
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, presence: true
              validates :config, type: Array
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
