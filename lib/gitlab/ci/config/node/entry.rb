module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Base abstract class for each configuration entry node.
        #
        class Entry
          class InvalidError < StandardError; end

          attr_accessor :description

          def initialize(value)
            @value = value
            @nodes = {}
            @errors = []

            prevalidate!
          end

          def process!
            return if leaf?
            return unless valid?

            compose!

            nodes.each(&:process!)
            nodes.each(&:validate!)
          end

          def nodes
            @nodes.values
          end

          def valid?
            errors.none?
          end

          def leaf?
            allowed_nodes.none?
          end

          def errors
            @errors + nodes.map(&:errors).flatten
          end

          def allowed_nodes
            {}
          end

          def validate!
            raise NotImplementedError
          end

          def value
            raise NotImplementedError
          end

          private

          def prevalidate!
          end

          def compose!
            allowed_nodes.each do |key, essence|
              @nodes[key] = create_node(key, essence)
            end
          end

          def create_node(key, essence)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
