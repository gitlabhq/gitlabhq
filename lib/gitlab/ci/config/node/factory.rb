module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Factory class responsible for fabricating node entry objects.
        #
        # It uses Fluent Interface pattern to set all necessary attributes.
        #
        class Factory
          class InvalidFactory < StandardError; end

          def initialize(entry_class)
            @entry_class = entry_class
            @attributes = {}
          end

          def with_value(value)
            @attributes[:value] = value
            self
          end

          def with_description(description)
            @attributes[:description] = description
            self
          end

          def null_node
            @entry_class = Node::Null
            self
          end

          def create!
            raise InvalidFactory unless @attributes.has_key?(:value)

            @entry_class.new(@attributes[:value]).tap do |entry|
              entry.description = @attributes[:description]
            end
          end
        end
      end
    end
  end
end
