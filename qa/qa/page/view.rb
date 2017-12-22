module QA
  module Page
    class View
      attr_reader :path, :elements

      def initialize(path, elements)
        @path = path
        @elements = elements
      end

      def pathname
        Pathname.new(File.join( __dir__, '../../../', @path))
          .cleanpath.expand_path
      end

      def errors
        ##
        # Reduce required elements by streaming views and making assertions on
        # elements' patterns.
        #
        @missing ||= @elements.dup.tap do |elements|
          File.new(pathname.to_s).foreach do |line|
            elements.reject! { |element| element.matches?(line) }
          end
        end

        @missing.map do |missing|
          "Missing element `#{missing}` in `#{pathname}` view partial!"
        end
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
