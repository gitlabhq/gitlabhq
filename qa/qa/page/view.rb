module QA
  module Page
    class View
      attr_reader :path, :elements

      def initialize(path, elements)
        @path = path
        @elements = elements
      end

      def pathname
        @pathname ||= Pathname.new(File.join(__dir__, '../../../', @path))
          .cleanpath.expand_path
      end

      def errors
        unless pathname.readable?
          return ["Missing view partial `#{pathname}`!"]
        end

        ##
        # Reduce required elements by streaming view and making assertions on
        # elements' existence.
        #
        @missing ||= @elements.dup.tap do |elements|
          File.foreach(pathname.to_s) do |line|
            elements.reject! { |element| element.matches?(line) }
          end
        end

        @missing.map do |missing|
          "Missing element `#{missing.name}` in `#{pathname}` view partial!"
        end
      end

      def self.evaluate(&block)
        Page::View::DSL.new.tap do |evaluator|
          evaluator.instance_exec(&block) if block_given?
        end
      end

      class DSL
        attr_reader :elements

        def initialize
          @elements = []
        end

        def element(name, pattern = nil)
          @elements.push(Page::Element.new(name, pattern))
        end
      end
    end
  end
end
