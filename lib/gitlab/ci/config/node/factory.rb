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
              fabricate(Node::Undefined, @node)
            else
              fabricate(@node, @attributes[:value])
            end
          end

          def self.fabricate(node, value, **attributes)
            node.new(value).tap do |entry|
              entry.key = attributes[:key]
              entry.parent = attributes[:parent]
              entry.description = attributes[:description]
            end
          end

          private

          def fabricate(node, value)
            self.class.fabricate(node, value, @attributes)
          end
        end
      end
    end
  end
end
