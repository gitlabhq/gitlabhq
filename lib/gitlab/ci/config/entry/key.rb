# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a key.
        #
        class Key < ::Gitlab::Config::Entry::Simplifiable
          strategy :SimpleKey, if: ->(config) { config.is_a?(String) || config.is_a?(Symbol) }
          strategy :ComplexKey, if: ->(config) { config.is_a?(Hash) }

          class SimpleKey < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, key: true
            end

            def self.default
              'default'
            end

            def value
              super.to_s
            end
          end

          class ComplexKey < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Attributable
            include ::Gitlab::Config::Entry::Configurable

            ALLOWED_KEYS = %i[files files_commits prefix].freeze

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :config, only_one_of_keys: { in: %i[files files_commits] }
            end

            entry :files, Entry::Files,
              description: 'Files that should be used to build the key'
            entry :files_commits, Entry::Files,
              description: 'Files that should be used to build the key using commit hash'
            entry :prefix, Entry::Prefix,
              description: 'Prefix that is added to the final cache key'
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
            def errors
              ["#{location} should be a hash, a string or a symbol"]
            end
          end

          def self.default
            'default'
          end
        end
      end
    end
  end
end
