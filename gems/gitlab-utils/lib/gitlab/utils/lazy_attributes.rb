# frozen_string_literal: true

module Gitlab
  module Utils
    module LazyAttributes
      extend ActiveSupport::Concern
      include Gitlab::Utils::StrongMemoize

      class_methods do
        def lazy_attr_reader(*one_or_more_names, type: nil)
          names = Array.wrap(one_or_more_names)
          names.each { |name| define_lazy_reader(name, type: type) }
        end

        def lazy_attr_accessor(*one_or_more_names, type: nil)
          names = Array.wrap(one_or_more_names)
          names.each do |name|
            define_lazy_reader(name, type: type)
            define_lazy_writer(name)
          end
        end

        private

        def define_lazy_reader(name, type:)
          define_method(name) do
            strong_memoize("#{name}_lazy_loaded") do
              value = instance_variable_get("@#{name}")
              value = value.call if value.respond_to?(:call)
              value = nil if type && !value.is_a?(type)
              value
            end
          end
        end

        def define_lazy_writer(name)
          define_method("#{name}=") do |value|
            clear_memoization("#{name}_lazy_loaded")
            instance_variable_set("@#{name}", value)
          end
        end
      end
    end
  end
end
