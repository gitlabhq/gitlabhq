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
          end

          def process!
            return if leaf?
            return unless valid?

            compose!

            nodes.each(&:process!)
            nodes.each(&:validate!)
          end

          def compose!
            allowed_nodes.each do |key, entry|
              add_node(key, entry)
            end
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

          def method_missing(name, *args)
            super unless allowed_nodes.has_key?(name)
            raise InvalidError unless valid?

            @nodes[name].try(:value)
          end

          def add_node(key, entry)
            raise NotImplementedError
          end

          def value
            raise NotImplementedError
          end

          def validate!
            raise NotImplementedError
          end
        end
      end
    end
  end
end
