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

            attributes :if, :when

            entry :changes, Entry::Rules::Rule::Changes,
              description: 'File change condition rule.'

            # TODO: Remove `disable_simple_exists_paths_limit` in https://gitlab.com/gitlab-org/gitlab/-/issues/456276.
            entry :exists, Entry::Rules::Rule::Exists,
              description: 'File exists condition rule.',
              metadata: { disable_simple_exists_paths_limit: true }

            validations do
              validates :config, presence: true
              validates :config, type: { with: Hash }
              validates :config, allowed_keys: ALLOWED_KEYS

              with_options allow_nil: true do
                validates :if, expression: true
                validates :when, allowed_values: { in: ALLOWED_WHEN }
              end
            end

            def value
              config.merge(
                changes: (changes_value if changes_defined?),
                exists: (exists_value if exists_defined?)
              ).compact
            end
          end
        end
      end
    end
  end
end
