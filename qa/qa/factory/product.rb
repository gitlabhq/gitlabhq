require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      attr_reader :factory

      def initialize(factory)
        @factory = factory

        define_attributes
      end

      def visit!
        visit(web_url)
      end

      def populate(*attributes)
        attributes.each(&method(:public_send))
      end

      private

      def define_attributes
        factory.class.attributes_names.each do |name|
          define_singleton_method(name) do
            factory.public_send(name)
          end
        end
      end
    end
  end
end
