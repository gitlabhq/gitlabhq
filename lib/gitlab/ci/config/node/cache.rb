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
            validate :keys

            def unknown_keys
              return [] unless config.is_a?(Hash)
              config.keys - allowed_keys
            end

            def keys
              if unknown_keys.any?
                errors.add(:config, "contains unknown keys #{unknown_keys}")
              end
            end
          end

          def allowed_keys
            self.class.nodes.keys
          end
        end
      end
    end
  end
end
