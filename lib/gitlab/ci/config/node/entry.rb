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

            unless leaf? || value.is_a?(Hash)
              @errors << 'should be a configuration entry with hash value'
            end
          end

          def process!
            return if leaf? || !valid?

            keys.each do |key, entry_class|
              if @value.has_key?(key)
                entry = entry_class.new(@value[key], @root, self)
              else
                entry = Node::Null.new(nil, @root, self)
              end

              @nodes[key] = entry
            end

            nodes.each(&:process!)
            nodes.each(&:validate!)
          end

          def nodes
            @nodes.values
          end

          def errors
            @errors + nodes.map(&:errors).flatten
          end

          def valid?
            errors.none?
          end

          def leaf?
            keys.none?
          end

          def keys
            self.class.nodes || {}
          end

          def method_missing(name, *args)
            super unless keys.has_key?(name)
            raise InvalidError unless valid?

            @nodes[name].value
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

          class << self
            attr_reader :nodes

            private

            def add_node(symbol, entry_class)
              (@nodes ||= {}).merge!(symbol.to_sym => entry_class)
            end
          end
        end
      end
    end
  end
end
