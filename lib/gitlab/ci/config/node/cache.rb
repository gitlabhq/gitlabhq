module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a cache configuration
        #
        class Cache < Entry
          include Configurable

          node :key, Key,
            description: 'Cache key used to define a cache affinity.'

          node :untracked, Boolean,
            description: 'Cache all untracked files.'

          node :paths, Paths,
            description: 'Specify which paths should be cached across builds.'

          validations do
            validates :config, allowed_keys: true
          end
        end
      end
    end
  end
end
