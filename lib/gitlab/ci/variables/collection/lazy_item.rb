# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Collection
        # LazyItem wraps a variable whose value is computed on-demand.
        class LazyItem
          include Gitlab::Utils::StrongMemoize

          attr_reader :key

          def initialize(key:, value_proc:, public: true, file: false, masked: false, raw: false)
            @key = key
            @value_proc = value_proc
            @options = { public: public, file: file, masked: masked, raw: raw }
          end

          def value
            resolved_item&.value
          end

          def raw?
            @options[:raw]
          end
          alias_method :raw, :raw?

          def file?
            @options[:file]
          end

          def masked?
            @options[:masked]
          end

          def [](attr_key)
            return @key if attr_key == :key
            return value if attr_key == :value

            resolved_item&.[](attr_key)
          end

          def ==(other)
            to_runner_variable == Item.fabricate(other).to_runner_variable
          end

          def depends_on
            nil
          end

          def to_runner_variable
            resolved_item&.to_runner_variable
          end

          def to_hash_variable
            resolved_item&.to_hash_variable
          end

          def to_s
            "LazyItem(#{@key})"
          end

          private

          def resolved_item
            result = @value_proc.call
            return if result.nil?

            Item.new(key: @key, value: result, **@options)
          end
          strong_memoize_attr :resolved_item
        end
      end
    end
  end
end
