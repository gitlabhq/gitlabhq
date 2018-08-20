module QA
  module Page
    class Element
      attr_reader :name, :required

      def initialize(name, required = true)
        @name = name

        unless !!required == required
          warn "[QA] DEPRECATED TYPING: element #{name}, #{required} should be a boolean!"
        end

        @required = required
      end

      def required?
        !!required
      end

      def selector
        /['"]data-qa-selector['"]: ['"]#{@name}['"]/
      end

      def selector_css
        %Q([data-qa-selector="#{@name}"])
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
    end
  end
end
