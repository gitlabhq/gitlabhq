module QA
  module Page
    class Element
      attr_reader :name

      def initialize(name, pattern)
        @name = name
        @pattern = pattern
      end

      def expression?
        @pattern.is_a?(Regexp)
      end

      def matches?(line)
        if expression?
          line =~ pattern
        else
          line.includes?(pattern)
        end
      end
    end
  end
end
