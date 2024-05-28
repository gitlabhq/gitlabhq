# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Extendable
        class Entry
          include Gitlab::Utils::StrongMemoize

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
            strong_memoize(:value) do
              @context.fetch(@key)
            end
          end

          def base_hashes!
            strong_memoize(:base_hashes) do
              extends_keys.map do |key|
                Extendable::Entry
                  .new(key, @context, self)
                  .extend!
              end
            end
          end

          def extends_keys
            strong_memoize(:extends_keys) do
              next unless extensible?

              Array(value.fetch(:extends)).map(&:to_s).map(&:to_sym)
            end
          end

          def ancestors
            strong_memoize(:ancestors) do
              Array(@parent&.ancestors) + Array(@parent&.key)
            end
          end

          def extend!
            return value unless extensible?

            if unknown_extensions.any?
              raise Entry::InvalidExtensionError,
                "#{key}: unknown keys in `extends` (#{show_keys(unknown_extensions)})"
            end

            if invalid_bases.any?
              raise Entry::InvalidExtensionError,
                "#{key}: invalid base hashes in `extends` (#{show_keys(invalid_bases)})"
            end

            if nesting_too_deep?
              raise Entry::NestingTooDeepError,
                "#{key}: nesting too deep in `extends`"
            end

            if circular_dependency?
              raise Entry::CircularDependencyError,
                "#{key}: circular dependency detected in `extends`"
            end

            merged = {}
            base_hashes!.each { |h| merged.deep_merge!(h) }

            @context[key] = merged.deep_merge!(value)
          end

          private

          def show_keys(keys)
            keys.join(', ')
          end

          def nesting_too_deep?
            ancestors.count > MAX_NESTING_LEVELS
          end

          def circular_dependency?
            ancestors.include?(key) # rubocop:disable Performance/AncestorsInclude
          end

          def unknown_extensions
            strong_memoize(:unknown_extensions) do
              extends_keys.reject { |key| @context.key?(key) }
            end
          end

          def invalid_bases
            strong_memoize(:invalid_bases) do
              extends_keys.reject { |key| @context[key].is_a?(Hash) }
            end
          end
        end
      end
    end
  end
end
