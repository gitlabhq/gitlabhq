module Gitlab
  module Diff
    class Highlight
      def self.process_diff_lines(file_name, diff_lines)
        processor = new(file_name, diff_lines)
        processor.highlight
      end

      def initialize(file_name, diff_lines)
        text_lines          = diff_lines.map(&:text)
        @file_name          = file_name
        @diff_lines         = diff_lines
        @diff_line_prefixes = text_lines.map { |line| line.sub!(/\A((\+|\-)\s*)/, '');$1 }
        @raw_lines          = text_lines.join("\n")
      end

      def highlight
        @code = unescape_html(@raw_lines)
        @highlighted_code = formatter.format(lexer.lex(@code))

        update_diff_lines
      end

      private

      def update_diff_lines
        @highlighted_code.lines.each_with_index do |line, i|
          diff_line = @diff_lines[i]

          # ignore highlighting for "match" lines
          next if diff_line.type == 'match'

          diff_line.text = "#{@diff_line_prefixes[i]}#{line}"
        end

        @diff_lines
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
