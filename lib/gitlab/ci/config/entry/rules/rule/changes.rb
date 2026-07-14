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

                ALLOWED_KEYS = %i[paths compare_to regexp].freeze
                REGEXP_MAX_LENGTH = ::Gitlab::Ci::Build::Rules::Rule::Clause::REGEXP_MAX_LENGTH

                attributes ALLOWED_KEYS

                validations do
                  validates :config, allowed_keys: ALLOWED_KEYS
                  validates :config, only_one_of_keys: { in: %i[paths regexp] }

                  with_options allow_nil: true do
                    validates :compare_to, type: String
                    validates :regexp, type: String, length: { maximum: REGEXP_MAX_LENGTH }
                  end

                  validates :paths,
                    array_of_strings: true,
                    length: { maximum: 50, too_long: "has too many entries (maximum %{count})" },
                    allow_nil: false,
                    if: -> { config.key?(:paths) }

                  validate :regexp_is_valid, if: -> { !regexp.nil? }

                  def regexp_is_valid
                    return unless regexp.is_a?(String)

                    Regexp.new(regexp)
                  rescue RegexpError => e
                    errors.add(:regexp, "is invalid: #{e.message}")
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
