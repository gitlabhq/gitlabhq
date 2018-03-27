module QA
  module Factory
    class Dependency
      Signature = Struct.new(:factory, :block)

      def initialize(name, factory, signature)
        @name = name
        @factory = factory
        @signature = signature
      end

      def overridden?
        !!@factory.public_send(@name)
      end

      def build!
        return if overridden?

        Builder.new(@signature, @factory).fabricate!.tap do |product|
          @factory.public_send("#{@name}=", product)
        end
      end

      class Builder
        def initialize(signature, caller_factory)
          @factory = signature.factory
          @block = signature.block
          @caller_factory = caller_factory
        end

        def fabricate!
          @factory.fabricate! do |factory|
            @block&.call(factory, @caller_factory)
          end
        end
      end
    end
  end
end
