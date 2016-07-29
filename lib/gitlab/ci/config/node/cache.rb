module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a cache configuration
        #
        class Cache < Entry
          include Configurable

          ALLOWED_KEYS = %i[key untracked paths]

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          node :key, Node::Key,
            description: 'Cache key used to define a cache affinity.'

          node :untracked, Node::Boolean,
            description: 'Cache all untracked files.'

          node :paths, Node::Paths,
            description: 'Specify which paths should be cached across builds.'
        end
      end
    end
  end
end
