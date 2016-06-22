module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Factory class responsible for fabricating node entry objects.
        #
        class Factory
          class InvalidFactory < StandardError; end

          def initialize(entry_class)
            @entry_class = entry_class
            @attributes = {}
          end

          def with(attributes)
            @attributes.merge!(attributes)
            self
          end

          def undefine!
            @entry_class = Node::Undefined
            self
          end

          def create!
            raise InvalidFactory unless @attributes.has_key?(:value)

            @entry_class.new(@attributes[:value]).tap do |entry|
              entry.description = @attributes[:description]
              entry.key = @attributes[:key]
            end
          end
        end
      end
    end
  end
end
