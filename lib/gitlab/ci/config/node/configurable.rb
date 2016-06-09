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

          def add_node(key, metadata)
            entry = create_entry(key, metadata[:class])
            entry.description = metadata[:description]

            @nodes[key] = entry
          end

          def create_entry(key, entry_class)
            if @value.has_key?(key)
              entry_class.new(@value[key], @root, self)
            else
              Node::Null.new(nil, @root, self)
            end
          end

          class_methods do
            attr_reader :nodes

            private

            def add_node(symbol, entry_class, metadata)
              node = { symbol.to_sym =>
                       { class: entry_class,
                         description: metadata[:description] } }

              (@nodes ||= {}).merge!(node)
            end
          end
        end
      end
    end
  end
end
