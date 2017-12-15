module QA
  module Factory
    class Base
      def self.fabricate!(*args)
        new.tap do |factory|
          yield factory if block_given?
          return factory.fabricate!(*args)
        end
      end

      def fabricate!(*_args)
        raise NotImplementedError
      end
    end
  end
end
