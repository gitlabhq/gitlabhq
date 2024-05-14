# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules
          class Rule
            class Exists < ::Gitlab::Config::Entry::Simplifiable
              MAX_PATHS = 50

              # TODO: We should not have the String support for `exists`.
              # Issue to remove: https://gitlab.com/gitlab-org/gitlab/-/issues/455040
              strategy :SimpleExists, if: ->(config) { config.is_a?(String) || config.is_a?(Array) || config.blank? }
              strategy :ComplexExists, if: ->(config) { config.is_a?(Hash) }

              class SimpleExists < ::Gitlab::Config::Entry::Node
                include ::Gitlab::Config::Entry::Validatable

                validations do
                  # TODO: Enforce 50-path limit in https://gitlab.com/gitlab-org/gitlab/-/issues/456276.
                  validates :config, array_of_strings: true,
                    length: { maximum: MAX_PATHS, too_long: 'has too many entries (maximum %{count})' },
                    if: -> { config.is_a?(Array) && !opt(:disable_simple_exists_paths_limit) }
                  validates :config, array_of_strings: true,
                    if: -> { config.is_a?(Array) && opt(:disable_simple_exists_paths_limit) }
                end

                def value
                  { paths: Array(config) }
                end
              end

              class ComplexExists < ::Gitlab::Config::Entry::Node
                include ::Gitlab::Config::Entry::Validatable
                include ::Gitlab::Config::Entry::Attributable

                ALLOWED_KEYS = %i[paths project ref].freeze
                REQUIRED_KEYS = %i[paths].freeze

                attributes ALLOWED_KEYS

                validations do
                  validates :config, allowed_keys: ALLOWED_KEYS
                  validates :config, required_keys: REQUIRED_KEYS
                  validates :config, required_keys: %i[project], if: :has_ref_value?

                  with_options allow_nil: true do
                    validates :paths, array_of_strings: true,
                      length: { maximum: MAX_PATHS, too_long: 'has too many entries (maximum %{count})' }
                    validates :project, type: String
                    validates :ref, type: String
                  end
                end

                def value
                  config.merge(
                    paths: Array(paths)
                  ).compact
                end
              end

              class UnknownStrategy < ::Gitlab::Config::Entry::Node
                def errors
                  ["#{location} should be a string, an array of strings, or a hash"]
                end
              end
            end
          end
        end
      end
    end
  end
end
