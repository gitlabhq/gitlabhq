require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      attr_reader :web_url

      Attribute = Struct.new(:name, :block)

      def initialize(web_url)
        @web_url = web_url
      end

      def visit!
        visit @web_url
      end

      def self.populate!(factory, web_url)
        new(web_url).tap do |product|
          factory.class.attributes.each_value do |attribute|
            product.instance_exec(factory, attribute.block) do |factory, block|
              value = block.call(factory)
              product.define_singleton_method(attribute.name) { value }
            end
          end
        end
      end
    end
  end
end
