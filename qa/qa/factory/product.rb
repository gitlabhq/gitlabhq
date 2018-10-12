require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      def initialize
        @location = current_url
      end

      def visit!
        visit @location
      end

      def self.populate!(factory)
        new.tap do |product|
          factory.class.attributes_names.each do |name|
            product.define_singleton_method(name) do
              factory.public_send(name)
            end
          end
        end
      end
    end
  end
end
