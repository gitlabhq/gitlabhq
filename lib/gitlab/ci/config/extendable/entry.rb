# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Extendable
        class Entry
          InvalidExtensionError = Class.new(Extendable::ExtensionError)
          CircularDependencyError = Class.new(Extendable::ExtensionError)
          NestingTooDeepError = Class.new(Extendable::ExtensionError)

          MAX_NESTING_LEVELS = 10

          attr_reader :key

          def initialize(key, context, parent = nil)
            @key = key
            @context = context
            @parent = parent

            unless @context.key?(@key)
              raise StandardError, 'Invalid entry key!'
            end
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

          def ancestors
            @ancestors ||= Array(@parent&.ancestors) + Array(@parent&.key)
          end

          def extend!
            return value unless extensible?

            if unknown_extension?
              raise Entry::InvalidExtensionError,
                    "#{key}: unknown key in `extends`"
            end

            if invalid_base?
              raise Entry::InvalidExtensionError,
                    "#{key}: invalid base hash in `extends`"
            end

            if nesting_too_deep?
              raise Entry::NestingTooDeepError,
                    "#{key}: nesting too deep in `extends`"
            end

            if circular_dependency?
              raise Entry::CircularDependencyError,
                    "#{key}: circular dependency detected in `extends`"
            end

            @context[key] = base_hash!.deep_merge(value)
          end

          private

          def nesting_too_deep?
            ancestors.count > MAX_NESTING_LEVELS
          end

          def circular_dependency?
            ancestors.include?(key)
          end

          def unknown_extension?
            !@context.key?(extends_key)
          end

          def invalid_base?
            !@context[extends_key].is_a?(Hash)
          end
        end
      end
    end
  end
end
