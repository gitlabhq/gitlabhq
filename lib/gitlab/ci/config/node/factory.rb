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

          def value(value)
            @value = value
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
              Node::Undefined.new(@node, @attributes)
            else
              @node.new(@value, @attributes)
            end
          end
        end
      end
    end
  end
end
