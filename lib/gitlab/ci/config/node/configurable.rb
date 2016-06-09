module Gitlab
  module Ci
    class Config
      module Node
        module Configurable
          extend ActiveSupport::Concern

          def keys
            self.class.nodes || {}
          end

          private

          def add_node(key, entry_class)
            if @value.has_key?(key)
              entry = entry_class.new(@value[key], @root, self)
            else
              entry = Node::Null.new(nil, @root, self)
            end

            @nodes[key] = entry
          end

          class_methods do
            attr_reader :nodes

            private

            def add_node(symbol, entry_class)
              node = { symbol.to_sym => entry_class }

              (@nodes ||= {}).merge!(node)
            end
          end
        end
      end
    end
  end
end
