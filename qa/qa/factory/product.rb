require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      def initialize(factory)
        @factory = factory
        @location = current_url
      end

      def visit!
        visit @location
      end

      def self.populate!(factory)
        raise ArgumentError unless block_given?

        yield factory

        new(factory)
      end
    end
  end
end
