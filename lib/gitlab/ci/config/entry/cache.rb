module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a cache configuration
        #
        class Cache < Node
          include Configurable

          ALLOWED_KEYS = %i[key untracked paths]

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          node :key, Entry::Key,
            description: 'Cache key used to define a cache affinity.'

          node :untracked, Entry::Boolean,
            description: 'Cache all untracked files.'

          node :paths, Entry::Paths,
            description: 'Specify which paths should be cached across builds.'
        end
      end
    end
  end
end
