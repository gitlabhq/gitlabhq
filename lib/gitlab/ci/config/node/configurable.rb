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

          def allowed_nodes
            self.class.allowed_nodes || {}
          end

          private

          def prevalidate!
            unless @value.is_a?(Hash)
              @errors << 'should be a configuration entry with hash value'
            end
          end

          def create_node(key, factory)
            factory.with(value: @value[key])
            factory.nullify! unless @value.has_key?(key)
            factory.create!
          end

          class_methods do
            def allowed_nodes
              Hash[@allowed_nodes.map { |key, factory| [key, factory.dup] }]
            end

            private

            def allow_node(symbol, entry_class, metadata)
              factory = Node::Factory.new(entry_class)
                .with(description: metadata[:description])

              define_method(symbol) do
                raise Entry::InvalidError unless valid?

                @nodes[symbol].try(:value)
              end

              (@allowed_nodes ||= {}).merge!(symbol => factory)
            end
          end
        end
      end
    end
  end
end
