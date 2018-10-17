require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      NoValueError = Class.new(RuntimeError)

      attr_reader :factory, :web_url

      Attribute = Struct.new(:name, :block)

      def initialize(factory, web_url)
        @factory = factory
        @web_url = web_url

        populate_attributes!
      end

      def visit!
        visit(web_url)
      end

      def self.populate!(factory, web_url)
        new(factory, web_url)
      end

      private

      def populate_attributes!
        factory.class.attributes.each do |attribute|
          instance_exec(factory, attribute.block) do |factory, block|
            value = attribute_value(attribute, block)

            raise NoValueError, "No value was computed for product #{attribute.name} of factory #{factory.class.name}." unless value

            define_singleton_method(attribute.name) { value }
          end
        end
      end

      def attribute_value(attribute, block)
        factory.api_resource&.dig(attribute.name) ||
          (block && block.call(factory)) ||
          (factory.respond_to?(attribute.name) && factory.public_send(attribute.name))
      end
    end
  end
end
