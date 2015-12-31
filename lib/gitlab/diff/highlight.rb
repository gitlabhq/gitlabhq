module Gitlab
  module Diff
    class Highlight
      # Apply syntax highlight to provided source code
      #
      # file_name - The file name related to the code.
      # lines     - It can be an Array of Gitlab::Diff::Line objects or simple Strings.
      #             When passing Strings you need to provide the required 'end of lines'
      #             chars ("\n") for each String given that we don't append them automatically.
      #
      # Returns an Array with the processed items.
      def self.process_diff_lines(file_name, lines)
        processor = new(file_name, lines)
        processor.highlight
      end

      def initialize(file_name, lines)
        @file_name  = file_name
        @lines      = lines
      end

      def highlight
        return [] if @lines.empty?

        extract_line_prefixes

        @code             = unescape_html(raw_content)
        @highlighted_code = formatter.format(lexer.lex(@code))

        is_diff_line? ? update_diff_lines : @highlighted_code.lines
      end

      private

      def is_diff_line?
        @lines.first.is_a?(Gitlab::Diff::Line)
      end

      def text_lines
        @text_lines ||= (is_diff_line? ? @lines.map(&:text) : @lines)
      end

      def raw_content
        @raw_content ||= text_lines.join(is_diff_line? ? "\n" : nil)
      end

      def extract_line_prefixes
        @diff_line_prefixes ||= begin
          if is_diff_line?
            text_lines.map { |line| line.sub!(/\A((\+|\-)\s*)/, '');$1 }
          else
            []
          end
        end
      end

      def update_diff_lines
        @highlighted_code.lines.each_with_index do |line, i|
          diff_line = @lines[i]

          # ignore highlighting for "match" lines
          next if diff_line.type == 'match'

          diff_line.text = "#{@diff_line_prefixes[i]}#{line}"
        end

        @lines
      end

      def lexer
        parent = Rouge::Lexer.guess(filename: @file_name, source: @code).new rescue Rouge::Lexers::PlainText.new
        Rouge::Lexers::GitlabDiff.new(parent_lexer: parent)
      end

      def unescape_html(content)
        text = CGI.unescapeHTML(content)
        text.gsub!('&nbsp;', ' ')
        text
      end

      def formatter
        Rouge::Formatters::HTMLGitlab.new(
          nowrap: true,
          cssclass: 'code highlight',
          lineanchors: true,
          lineanchorsid: 'LC'
        )
      end
    end
  end
end
