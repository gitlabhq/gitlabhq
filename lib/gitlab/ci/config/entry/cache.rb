# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Cache < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[key untracked paths when policy unprotect fallback_keys].freeze
          ALLOWED_POLICY = /pull-push|push|pull|\$\w{1,255}*/
          DEFAULT_POLICY = 'pull-push'
          ALLOWED_WHEN = %w[on_success on_failure always].freeze
          DEFAULT_WHEN = 'on_success'
          DEFAULT_FALLBACK_KEYS = [].freeze

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :policy, type: String, allow_blank: true, format: {
              with: ALLOWED_POLICY,
              message: "should be a variable or one of: pull-push, push, pull"
            }

            with_options allow_nil: true do
              validates :when, type: String, inclusion: {
                in: ALLOWED_WHEN,
                message: "should be one of: #{ALLOWED_WHEN.join(', ')}"
              }

              validates :fallback_keys, length: { maximum: 5, too_long: "has to many entries (maximum %{count})" }
            end
          end

          entry :key, Entry::Key,
            description: 'Cache key used to define a cache affinity.'

          entry :unprotect, ::Gitlab::Config::Entry::Boolean,
            description: 'Unprotect the cache from a protected ref.'

          entry :untracked, ::Gitlab::Config::Entry::Boolean,
            description: 'Cache all untracked files.'

          entry :paths, Entry::Paths,
            description: 'Specify which paths should be cached across builds.'

          entry :fallback_keys, ::Gitlab::Config::Entry::ArrayOfStrings,
            description: 'List of keys to download cache from if no cache hit occurred for key'

          attributes :policy, :when, :unprotect, :fallback_keys

          def value
            result = super

            result[:key] = key_value
            result[:unprotect] = unprotect || false
            result[:policy] = policy || DEFAULT_POLICY
            # Use self.when to avoid conflict with reserved word
            result[:when] = self.when || DEFAULT_WHEN
            result[:fallback_keys] = fallback_keys || DEFAULT_FALLBACK_KEYS

            result
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
          end
        end
      end
    end
  end
end
