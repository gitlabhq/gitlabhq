module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a cache configuration
        #
        class Cache < Entry
          include Configurable

          validations do
            validate :allowed_keys

            def unknown_keys
              return [] unless @node.config.is_a?(Hash)

              @node.config.keys - @node.class.nodes.keys
            end

            def allowed_keys
              if unknown_keys.any?
                errors.add(:config, "contains unknown keys #{unknown_keys}")
              end
            end
          end

          node :key, Node::Key,
            description: 'Cache key used to define a cache affinity.'

          node :untracked, Boolean,
            description: 'Cache all untracked files.'

          node :paths, Paths,
            description: 'Specify which paths should be cached across builds.'
        end
      end
    end
  end
end
