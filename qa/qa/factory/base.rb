module QA
  module Factory
    class Base
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

      def self.dependencies
        @dependencies ||= {}
      end

      def self.dependency(factory, as:, &block)
        as.tap do |name|
          class_eval { attr_accessor name }

          Dependency::Signature.new(factory, block).tap do |signature|
            dependencies.store(name, signature)
          end
        end
      end
    end
  end
end
