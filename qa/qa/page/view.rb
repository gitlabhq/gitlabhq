module QA
  module Page
    class View
      attr_reader :path, :elements

      def initialize(path, elements)
        @path = path
        @elements = elements
      end

      def self.evaluate(&block)
        Page::View::DSL.new.tap do |evaluator|
          evaluator.instance_exec(&block)
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
