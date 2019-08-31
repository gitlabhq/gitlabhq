# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a cache configuration
        #
        class Cache < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[key untracked paths policy].freeze
          DEFAULT_POLICY = 'pull-push'

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :policy, inclusion: { in: %w[pull-push push pull], message: 'should be pull-push, push, or pull' }, allow_blank: true
          end

          entry :key, Entry::Key,
            description: 'Cache key used to define a cache affinity.'

          entry :untracked, ::Gitlab::Config::Entry::Boolean,
            description: 'Cache all untracked files.'

          entry :paths, Entry::Paths,
            description: 'Specify which paths should be cached across builds.'

          helpers :key

          attributes :policy

          def value
            result = super

            result[:key] = key_value
            result[:policy] = policy || DEFAULT_POLICY

            result
          end
        end
      end
    end
  end
end
