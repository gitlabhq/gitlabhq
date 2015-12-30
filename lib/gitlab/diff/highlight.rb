module Gitlab
  module Diff
    class Highlight
      def self.process_diff_lines(diff_file)
        processor = new(diff_file)
        processor.highlight
      end

      def initialize(diff_file)
        text_lines          = diff_file.diff_lines.map(&:text)
        @diff_file          = diff_file
        @diff_lines         = diff_file.diff_lines
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
          @diff_lines[i].text = "#{@diff_line_prefixes[i]}#{line}"
        end

        @diff_lines
      end

      def lexer
        parent = Rouge::Lexer.guess(filename: @diff_file.new_path, source: @code).new rescue Rouge::Lexers::PlainText.new
        Rouge::Lexers::GitlabDiff.new(parent_lexer: parent)
      end

      def unescape_html(content)
        text = CGI.unescapeHTML(content)
        text.gsub!('&nbsp;', ' ')
        text
      end

      def formatter
        @formatter ||= Rouge::Formatters::HTMLGitlab.new(
          nowrap: true,
          cssclass: 'code highlight',
          lineanchors: true,
          lineanchorsid: 'LC'
        )
      end
    end
  end
end
