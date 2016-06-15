require 'cgi'

module Rouge
  module Formatters
    class HTMLGitlab < Rouge::Formatter
      tag 'html_gitlab'

      # Creates a new <tt>Rouge::Formatter::HTMLGitlab</tt> instance.
      #
      # [+cssclass+]        CSS class for the wrapping <tt><div></tt> tag
      #                     (default: 'highlight').
      # [+lineanchors+]     If set to true the formatter will wrap each output
      #                     line in an anchor tag with a name of L-linenumber.
      #                     This allows easy linking to certain lines
      #                     (default: false).
      # [+lineanchorsid+]   If lineanchors is true the name of the anchors can
      #                     be changed with lineanchorsid to e.g. foo-linenumber
      #                     (default: 'L').
      def initialize(
          cssclass: 'highlight',
          lineanchors: false,
          lineanchorsid: 'L'
      )
        @cssclass = cssclass
        @lineanchors = lineanchors
        @lineanchorsid = lineanchorsid
      end

      def render(tokens)
        data = process_tokens(tokens)

        wrap_lines(data[:code])
      end

      alias_method :format, :render

      private

      def process_tokens(tokens)
        rendered = []
        current_line = ''

        tokens.each do |tok, val|
          # In the case of multi-line values (e.g. comments), we need to apply
          # styling to each line since span elements are inline.
          val.lines.each do |line|
            stripped = line.chomp
            current_line << span(tok, stripped)

            if line.end_with?("\n")
              rendered << current_line
              current_line = ''
            end
          end
        end

        # Add leftover text
        rendered << current_line if current_line.present?

        { code: rendered }
      end

      def wrap_lines(lines)
        if @lineanchors
          lines = lines.each_with_index.map do |line, index|
            number = index + @linenostart

            "<span id=\"#{@lineanchorsid}#{number}\" class=\"line\">#{line}" \
            '</span>'
          end
        end

        lines.join("\n")
      end

      def span(tok, val)
        # http://stackoverflow.com/a/1600584/2587286
        val = CGI.escapeHTML(val)

        if tok.shortname.empty?
          val
        else
          "<span class=\"#{tok.shortname}\">#{val}</span>"
        end
      end
    end
  end
end
