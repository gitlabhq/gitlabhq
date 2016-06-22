module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Factory class responsible for fabricating node entry objects.
        #
        class Factory
          class InvalidFactory < StandardError; end

          def initialize(node)
            @node = node
            @attributes = {}
          end

          def with(attributes)
            @attributes.merge!(attributes)
            self
          end

          def undefine!
            @attributes[:value] = @node.dup
            @node = Node::Undefined
            self
          end

          def create!
            raise InvalidFactory unless @attributes.has_key?(:value)

            @node.new(@attributes[:value]).tap do |entry|
              entry.description = @attributes[:description]
              entry.key = @attributes[:key]
            end
          end
        end
      end
    end
  end
end
