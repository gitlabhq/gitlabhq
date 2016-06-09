module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This mixin is responsible for adding DSL, which purpose is to
        # simplifly process of adding child nodes.
        #
        # This can be used only if parent node is a configuration entry that
        # holds a hash as a configuration value, for example:
        #
        # job:
        #   script: ...
        #   artifacts: ...
        #
        module Configurable
          extend ActiveSupport::Concern

          def initialize(*)
            super

            unless leaf? || has_config?
              @errors << 'should be a configuration entry with hash value'
            end
          end

          def allowed_nodes
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
