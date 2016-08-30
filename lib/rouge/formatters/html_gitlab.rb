module Rouge
  module Formatters
    class HTMLGitlab < Rouge::Formatters::HTML
      tag 'html_gitlab'

      # Creates a new <tt>Rouge::Formatter::HTMLGitlab</tt> instance.
      #
      # [+linenostart+]     The line number for the first line (default: 1).
      def initialize(linenostart: 1)
        @linenostart = linenostart
        @line_number = linenostart
      end

      def stream(tokens, &b)
        is_first = true
        token_lines(tokens) do |line|
          yield "\n" unless is_first
          is_first = false

          yield %(<span id="LC#{@line_number}" class="line">)
          line.each { |token, value| yield span(token, value.chomp) }
          yield %(</span>)

          @line_number += 1
        end
      end
    end
  end
end
