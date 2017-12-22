module QA
  module Page
    class Element
      attr_reader :name

      def initialize(name, pattern)
        @name = name
        @pattern = pattern
      end

      def matches?(line)
        case @pattern
        when Regexp
          !!(line =~ @pattern)
        when String
          line.include?(@pattern)
        else
          raise ArgumentError, 'Pattern should be either String or Regexp!'
        end
      end
    end
  end
end
