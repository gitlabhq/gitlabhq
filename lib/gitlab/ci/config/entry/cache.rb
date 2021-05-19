# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Cache < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[key untracked paths when policy].freeze
          ALLOWED_POLICY = %w[pull-push push pull].freeze
          DEFAULT_POLICY = 'pull-push'
          ALLOWED_WHEN = %w[on_success on_failure always].freeze
          DEFAULT_WHEN = 'on_success'

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :policy,
              inclusion: { in: ALLOWED_POLICY, message: 'should be pull-push, push, or pull' },
              allow_blank: true

            with_options allow_nil: true do
              validates :when,
                  inclusion: {
                    in: ALLOWED_WHEN,
                    message: 'should be on_success, on_failure or always'
                  }
            end
          end

          entry :key, Entry::Key,
            description: 'Cache key used to define a cache affinity.'

          entry :untracked, ::Gitlab::Config::Entry::Boolean,
            description: 'Cache all untracked files.'

          entry :paths, Entry::Paths,
            description: 'Specify which paths should be cached across builds.'

          attributes :policy, :when

          def value
            result = super

            result[:key] = key_value
            result[:policy] = policy || DEFAULT_POLICY
            # Use self.when to avoid conflict with reserved word
            result[:when] = self.when || DEFAULT_WHEN

            result
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
          end
        end
      end
    end
  end
end
