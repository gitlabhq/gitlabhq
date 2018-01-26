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
          factory.class.attributes.each_value do |attribute|
            product.instance_exec(factory, attribute.block) do |factory, block|
              product.define_singleton_method(attribute.name) { block.call(factory) }
            end
          end
        end
      end
    end
  end
end
