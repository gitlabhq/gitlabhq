# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules
          class Rule
            class Changes < ::Gitlab::Config::Entry::Simplifiable
              strategy :SimpleChanges, if: ->(config) { config.is_a?(Array) }
              strategy :ComplexChanges, if: ->(config) { config.is_a?(Hash) }

              class SimpleChanges < ::Gitlab::Config::Entry::Node
                include ::Gitlab::Config::Entry::Validatable

                validations do
                  validates :config,
                    array_of_strings: true,
                    length: { maximum: 50, too_long: "has too many entries (maximum %{count})" }
                end

                def value
                  {
                    paths: config
                  }.compact
                end
              end

              class ComplexChanges < ::Gitlab::Config::Entry::Node
                include ::Gitlab::Config::Entry::Validatable
                include ::Gitlab::Config::Entry::Attributable

                ALLOWED_KEYS = %i[paths compare_to].freeze
                REQUIRED_KEYS = %i[paths].freeze

                attributes ALLOWED_KEYS

                validations do
                  validates :config, allowed_keys: ALLOWED_KEYS
                  validates :config, required_keys: REQUIRED_KEYS

                  with_options allow_nil: false do
                    validates :paths,
                      array_of_strings: true,
                      length: { maximum: 50, too_long: "has too many entries (maximum %{count})" }
                    validates :compare_to, type: String, allow_nil: true
                  end
                end
              end

              class UnknownStrategy < ::Gitlab::Config::Entry::Node
                def errors
                  ["#{location} should be an array or a hash"]
                end
              end
            end
          end
        end
      end
    end
  end
end
