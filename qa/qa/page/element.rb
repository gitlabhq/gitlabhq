module QA
  module Page
    class Element
      attr_reader :name

      def initialize(name, pattern)
        @name = name
        @pattern = pattern
      end

      def self.evaluate(&block)
        Page::Element::DSL.new.tap do |evaluator|
          evaluator.instance_exec(&block)

          return evaluator.elements
        end
      end

      class DSL
        attr_reader :elements

        def initialize
          @elements = []
        end

        def element(name, pattern)
          @elements.push(Page::Element.new(name, pattern))
        end
      end
    end
  end
end
