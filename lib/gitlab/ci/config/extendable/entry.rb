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

            raise StandardError, 'Invalid entry key!' unless @context.key?(@key)
          end

          def extensible?
            value.is_a?(Hash) && value.key?(:extends)
          end

          def value
            @value ||= @context.fetch(@key)
          end

          def base_hash!
            @base ||= Extendable::Entry
              .new(extends_key, @context, self)
              .extend!
          end

          def extends_key
            value.fetch(:extends).to_s.to_sym if extensible?
          end

          def path
            Array(@parent&.path).compact.push(key)
          end

          def extend!
            return value unless extensible?

            if unknown_extension?
              raise Extendable::Collection::InvalidExtensionError,
                    'Unknown extension!'
            end

            if invalid_base?
              raise Extendable::Collection::InvalidExtensionError,
                    'Invalid base hash!'
            end

            if circular_dependency?
              raise Extendable::Collection::CircularDependencyError
            end

            @context[key] = base_hash!.deep_merge(value)
          end

          private

          def circular_dependency?
            path.count(key) > 1
          end

          def unknown_extension?
            !@context.key?(key)
          end

          def invalid_base?
            !@context[extends_key].is_a?(Hash)
          end
        end
      end
    end
  end
end
