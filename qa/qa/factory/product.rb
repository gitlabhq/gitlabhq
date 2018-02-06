require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      Attribute = Struct.new(:name, :block)

      def initialize
        @location = current_url
      end

      def visit!
        visit @location
      end

      def self.populate!(factory)
        new.tap do |product|
          factory.attributes.each_value do |attribute|
            product.instance_exec(&attribute.block).tap do |value|
              product.define_singleton_method(attribute.name) { value }
            end
          end
        end
      end
    end
  end
end
