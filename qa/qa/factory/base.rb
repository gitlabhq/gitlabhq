require 'forwardable'

module QA
  module Factory
    class Base
      extend SingleForwardable

      def_delegators :evaluator, :dependency, :dependencies

      def fabricate!(*_args)
        raise NotImplementedError
      end

      def self.fabricate!(*args)
        Factory::Product.populate!(new) do |factory|
          yield factory if block_given?

          dependencies.each do |name, signature|
            Factory::Dependency.new(name, factory, signature).build!
          end

          factory.fabricate!(*args)
        end
      end

      def self.evaluator
        @evaluator ||= Factory::Base::DSL.new(self)
      end

      class DSL
        attr_reader :dependencies

        def initialize(base)
          @base = base
          @dependencies = {}
        end

        def dependency(factory, as:, &block)
          as.tap do |name|
            @base.class_eval { attr_accessor name }

            Dependency::Signature.new(factory, block).tap do |signature|
              dependencies.store(name, signature)
            end
          end
        end
      end
    end
  end
end
