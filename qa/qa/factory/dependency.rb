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

      def build!(parents: [])
        return if overridden?

        dependency = @dependency_signature.factory.fabricate!(parents: parents) do |factory|
          @dependency_signature.block&.call(factory, @caller_factory)
        end

        dependency.tap do |dependency|
          @caller_factory.public_send("#{@dependency_signature.name}=", dependency)
        end
      end
    end
  end
end
