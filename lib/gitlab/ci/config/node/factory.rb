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
            @metadata = {}
            @attributes = {}
          end

          def value(value)
            @value = value
            self
          end

          def metadata(metadata)
            @metadata.merge!(metadata)
            self
          end

          def with(attributes)
            @attributes.merge!(attributes)
            self
          end

          def create!
            raise InvalidFactory unless defined?(@value)

            ##
            # We assume that unspecified entry is undefined.
            # See issue #18775.
            #
            if @value.nil?
              Node::Undefined.new(
                fabricate_undefined
              )
            else
              fabricate(@node, @value)
            end
          end

          private

          def fabricate_undefined
            ##
            # If node has a default value we fabricate concrete node
            # with default value.
            #
            if @node.default.nil?
              fabricate(Node::Null)
            else
              fabricate(@node, @node.default)
            end
          end

          def fabricate(node, value = nil)
            node.new(value, @metadata).tap do |entry|
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
