module QA
  module Page
    class Element
      attr_reader :name

      def initialize(name, pattern = nil)
        @name = name
        @pattern = pattern || "qa-#{@name.to_s.tr('_', '-')}"
      end

      def expression
        if @pattern.is_a?(String)
          @_regexp ||= Regexp.new(Regexp.escape(@pattern))
        else
          @pattern
        end
      end

      def matches?(line)
        !!(line =~ expression)
      end

      def to_s
        @name
      end
    end
  end
end
