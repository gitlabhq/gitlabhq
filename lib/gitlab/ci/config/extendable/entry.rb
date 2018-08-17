module Gitlab
  module Ci
    class Config
      module Extendable
        class Entry
          attr_reader :key

          def initialize(key, context, parent = nil)
            @key = key
            @context = context
            @parent = parent
          end

          def valid?
            true
          end

          def value
            @value ||= @context.fetch(@key)
          end

          def base_hash
            Extendable::Entry
              .new(extends_key, @context, self)
              .extend!
          end

          def extensible?
            value.key?(:extends)
          end

          def extends_key
            value.fetch(:extends).to_s.to_sym
          end

          def path
            Array(@parent&.path).compact.push(key)
          end

          def extend!
            if circular_dependency?
              raise Extendable::Collection::CircularDependencyError
            end

            if invalid_extends_key?
              raise Extendable::Collection::InvalidExtensionError
            end

            if extensible?
              @context[key] = base_hash.deep_merge(value)
            else
              value
            end
          end

          private

          def circular_dependency?
            path.count(key) > 1
          end

          def invalid_extends_key?
            !@context.key?(key)
          end
        end
      end
    end
  end
end
