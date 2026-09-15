# frozen_string_literal: true

module Gitlab
  module Utils
    module LazyAttributes
      extend ActiveSupport::Concern
      include Gitlab::Utils::StrongMemoize

      class_methods do
        def lazy_attr_reader(*one_or_more_names, type: nil, cache_nil: true)
          names = Array.wrap(one_or_more_names)
          names.each { |name| define_lazy_reader(name, type: type, cache_nil: cache_nil) }
        end

        def lazy_attr_accessor(*one_or_more_names, type: nil)
          names = Array.wrap(one_or_more_names)
          names.each do |name|
            define_lazy_reader(name, type: type)
            define_lazy_writer(name)
          end
        end

        private

        def define_lazy_reader(name, type:, cache_nil: true)
          if cache_nil
            define_memoized_lazy_reader(name, type)
          else
            define_non_nil_lazy_reader(name, type)
          end
        end

        # Caches the first resolved value, including nil.
        def define_memoized_lazy_reader(name, type)
          define_method(name) do
            strong_memoize("#{name}_lazy_loaded") do
              resolve_lazy_attribute("@#{name}", type)
            end
          end
        end

        # Does not cache a nil result. The source is re-resolved on each read
        # until it yields a non-nil value, which is then cached. This avoids
        # permanently memoizing nil when the reader is evaluated before its
        # source is populated (e.g. the user before authentication).
        def define_non_nil_lazy_reader(name, type)
          memo = "@#{name}_lazy_memo"

          define_method(name) do
            next instance_variable_get(memo) if instance_variable_defined?(memo)

            value = resolve_lazy_attribute("@#{name}", type)
            instance_variable_set(memo, value) unless value.nil?
            value
          end
        end

        def define_lazy_writer(name)
          define_method("#{name}=") do |value|
            clear_memoization("#{name}_lazy_loaded")
            instance_variable_set("@#{name}", value)
          end
        end
      end

      private

      # Reads the backing ivar, resolves it if it is callable, and discards a
      # value that does not match the declared type.
      def resolve_lazy_attribute(ivar, type)
        value = instance_variable_get(ivar)
        value = value.call if value.respond_to?(:call)
        value = nil if type && !value.is_a?(type)
        value
      end
    end
  end
end
