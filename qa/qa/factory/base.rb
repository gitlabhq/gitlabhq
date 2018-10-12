# frozen_string_literal: true

require 'forwardable'

module QA
  module Factory
    class Base
      extend SingleForwardable

      def_delegators :evaluator, :attribute

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def self.fabricate!(*args)
        new.tap do |factory|
          yield factory if block_given?

          factory.fabricate!(*args)

          break Factory::Product.populate!(factory)
        end
      end

      def self.evaluator
        @evaluator ||= Factory::Base::DSL.new(self)
      end

      def self.attributes_module
        const_get(:Attributes)
      rescue NameError
        mod = const_set(:Attributes, Module.new)

        include mod

        mod
      end

      def self.attributes_names
        attributes_module.instance_methods.grep_v(/=$/)
      end

      class DSL
        def initialize(base)
          @base = base
        end

        def attribute(name, &block)
          @base.attributes_module.module_eval do
            attr_writer(name)

            define_method(name) do
              instance_variable_get("@#{name}") ||
                instance_variable_set("@#{name}", instance_exec(&block))
            end
          end
        end
      end
    end
  end
end
