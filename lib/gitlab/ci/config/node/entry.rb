module Gitlab
  module Ci
    class Config
      module Node
        class Entry
          include Config::ValidationHelpers

          attr_reader :value, :nodes, :parent

          def initialize(value, config, parent = nil)
            @value = value
            @config = config
            @parent = parent
            @nodes, @errors = [], []

            keys.each_key do |key|
              instance_variable_set("@#{key}", Null.new(nil, config, self))
            end
          end

          def process!
            return if leaf?

            keys.each do |key, entry_class|
              next unless @value.has_key?(key)

              entry = entry_class.new(@value[key], @config, self)
              instance_variable_set("@#{key}", entry)
              @nodes.append(entry)
            end

            nodes.each(&:process!)
            nodes.each(&:validate!)
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
