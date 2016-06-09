module Gitlab
  module Ci
    class Config
      module Node
        class Entry
          class InvalidError < StandardError; end

          def initialize(value, root = nil, parent = nil)
            @value = value
            @root = root
            @parent = parent
            @nodes = {}
            @errors = []

            unless leaf? || has_config?
              @errors << 'should be a configuration entry with hash value'
            end
          end

          def process!
            return if leaf? || invalid?

            compose!

            nodes.each(&:process!)
            nodes.each(&:validate!)
          end

          def compose!
            keys.each do |key, entry|
              add_node(key, entry)
            end
          end

          def nodes
            @nodes.values
          end

          def valid?
            errors.none?
          end

          def invalid?
            !valid?
          end

          def leaf?
            keys.none?
          end

          def has_config?
            @value.is_a?(Hash)
          end

          def keys
            {}
          end

          def errors
            @errors + nodes.map(&:errors).flatten
          end

          def method_missing(name, *args)
            super unless keys.has_key?(name)
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

          def description
            raise NotImplementedError
          end
        end
      end
    end
  end
end
