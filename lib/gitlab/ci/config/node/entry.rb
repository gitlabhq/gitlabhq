module Gitlab
  module Ci
    class Config
      module Node
        class Entry
          include Config::ValidationHelpers

          attr_reader :value, :config, :parent, :nodes, :errors

          def initialize(value, config, parent = nil)
            @value = value
            @config = config
            @parent = parent
            @nodes = {}
            @errors = []
          end

          def process!
            keys.each_pair do |key, entry|
              next unless @value.include?(key)
              @nodes[key] = entry.new(@value[key], config, self)
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
