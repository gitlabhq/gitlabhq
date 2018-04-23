require 'forwardable'

module QA
  module Factory
    class Base
      extend SingleForwardable

      def_delegators :evaluator, :dependency, :dependencies
      def_delegators :evaluator, :product, :attributes

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def self.fabricate!(*args)
        new.tap do |factory|
          yield factory if block_given?

          dependencies.each do |name, signature|
            Factory::Dependency.new(name, factory, signature).build!
          end

          factory.fabricate!(*args)

          break Factory::Product.populate!(factory)
        end
      end

      def self.evaluator
        @evaluator ||= Factory::Base::DSL.new(self)
      end

      class DSL
        attr_reader :dependencies, :attributes

        def initialize(base)
          @base = base
          @dependencies = {}
          @attributes = {}
        end

        def dependency(factory, as:, &block)
          as.tap do |name|
            @base.class_eval { attr_accessor name }

            Dependency::Signature.new(factory, block).tap do |signature|
              @dependencies.store(name, signature)
            end
          end
        end

        def product(attribute, &block)
          Product::Attribute.new(attribute, block).tap do |signature|
            @attributes.store(attribute, signature)
          end
        end
      end
    end
  end
end
