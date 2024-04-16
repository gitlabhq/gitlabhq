# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Include
          class Rules::Rule < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Configurable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[if exists when changes].freeze
            ALLOWED_WHEN = %w[never always].freeze

            # Remove `exists` when FF `ci_support_rules_exists_paths_and_project` is removed
            attributes :if, :exists, :when

            entry :changes, Entry::Rules::Rule::Changes,
              description: 'File change condition rule.'

            entry :exists, Entry::Rules::Rule::Exists,
              description: 'File exists condition rule.'

            validations do
              validates :config, presence: true
              validates :config, type: { with: Hash }
              validates :config, allowed_keys: ALLOWED_KEYS

              with_options allow_nil: true do
                validates :if, expression: true
                validates :exists, array_of_strings_or_string: true, allow_blank: true, unless: :complex_exists_enabled?
                validates :when, allowed_values: { in: ALLOWED_WHEN }
              end
            end

            def value
              if complex_exists_enabled?
                config.merge(
                  changes: (changes_value if changes_defined?),
                  exists: (exists_value if exists_defined?)
                ).compact
              else
                config.merge(
                  changes: (changes_value if changes_defined?)
                ).compact
              end
            end

            def complex_exists_enabled?
              ::Feature.enabled?(:ci_support_rules_exists_paths_and_project, ::Feature.current_request)
            end
          end
        end
      end
    end
  end
end
