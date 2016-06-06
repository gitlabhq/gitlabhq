module Gitlab
  module Ci
    class Config
      module Node
        class Entry
          attr_reader :hash, :config, :parent, :nodes, :errors

          def initialize(hash, config, parent = nil)
            @hash = hash
            @config = config
            @parent = parent
            @nodes = {}
            @errors = []
          end

          def process!
            keys.each_pair do |key, entry|
              next unless hash.include?(key)
              @nodes[key] = entry.new(hash[key], config, self)
            end

            @nodes.values.each(&:process!)
            @nodes.values.each(&:validate!)
          end

          def keys
            raise NotImplementedError
          end

          def validate!
            raise NotImplementedError
          end
        end
      end
    end
  end
end
