module QA
  module Factory
    class Dependency
      Signature = Struct.new(:name, :factory, :block)

      def initialize(caller_factory, dependency_signature)
        @caller_factory = caller_factory
        @dependency_signature = dependency_signature
      end

      def overridden?
        !!@caller_factory.public_send(@dependency_signature.name)
      end

      def build!
        return if overridden?

        Builder.new(@dependency_signature, @caller_factory).fabricate!.tap do |product|
          @caller_factory.public_send("#{@dependency_signature.name}=", product)
        end
      end

      class Builder
        def initialize(signature, caller_factory)
          @dependency_factory = signature.factory
          @dependency_factory_block = signature.block
          @caller_factory = caller_factory
        end

        def fabricate!
          @dependency_factory.fabricate! do |factory|
            @dependency_factory_block&.call(factory, @caller_factory)
          end
        end
      end
    end
  end
end
