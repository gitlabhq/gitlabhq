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

          def base
            Extendable::Entry
              .new(extends, @context, self)
              .extend!
          end

          def extensible?
            value.key?(:extends)
          end

          def extends
            value.fetch(:extends).to_sym
          end

          def path
            Array(@parent&.path).compact.push(key)
          end

          def extend!
            if path.count(key) > 1
              raise Extendable::Collection::CircularDependencyError
            end

            if extensible?
              @context[key] = base.deep_merge(value)
            else
              value
            end
          end
        end
      end
    end
  end
end
