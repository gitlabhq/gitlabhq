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

          def create!
            raise InvalidFactory unless @attributes.has_key?(:value)

            ##
            # We assume that unspecified entry is undefined.
            # See issue #18775.
            #
            if @attributes[:value].nil?
              node, value = Node::Undefined, @node
            else
              node, value = @node, @attributes[:value]
            end

            node.new(value).tap do |entry|
              entry.key = @attributes[:key]
              entry.parent = @attributes[:parent]
              entry.description = @attributes[:description]
            end
          end
        end
      end
    end
  end
end
