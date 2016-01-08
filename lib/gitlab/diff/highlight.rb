module Gitlab
  module Diff
    class Highlight
      attr_reader :diff_file

      delegate :repository, :old_path, :new_path, :old_ref, :new_ref,
        to: :diff_file, prefix: :diff

      # Apply syntax highlight to provided source code
      #
      # diff_file - an instance of Gitlab::Diff::File
      #
      # Returns an Array with the processed items.
      def self.process_diff_lines(diff_file)
        processor = new(diff_file)
        processor.highlight
      end

      def self.process_file(repository, ref, file_name)
        blob = repository.blob_at(ref, file_name)
        return [] unless blob

        content = blob.data
        lexer = Rouge::Lexer.guess(filename: file_name, source: content).new rescue Rouge::Lexers::PlainText.new
        formatter.format(lexer.lex(content)).lines
      end

      def self.formatter
        @formatter ||= Rouge::Formatters::HTMLGitlab.new(
                         nowrap: true,
                         cssclass: 'code highlight',
                         lineanchors: true,
                         lineanchorsid: 'LC'
                       )
      end

      def initialize(diff_file)
        @diff_file = diff_file
        @file_name = diff_file.new_path
        @lines     = diff_file.diff_lines
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
            text_lines.map { |line| line.sub!(/\A((\+|\-))/, '');$1 }
          else
            []
          end
        end
      end

      def update_diff_lines
        @highlighted_code.lines.each_with_index do |line, i|
          diff_line = @lines[i]
          line_prefix = @diff_line_prefixes[i] || ' '

          # ignore highlighting for "match" lines
          next if diff_line.type == 'match'

          case diff_line.type
          when 'new', nil
            diff_line.text = new_lines[diff_line.new_pos - 1].try(:gsub!, /\A\s/, line_prefix)
          when 'old'
            diff_line.text = old_lines[diff_line.old_pos - 1].try(:gsub!, /\A\s/, line_prefix)
          end
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
        self.class.formatter
      end

      def old_lines
        @old_lines ||= begin
          lines = self.class.process_file(diff_repository, diff_old_ref, diff_old_path)
          lines.map! { |line| " #{line}" }
        end
      end

      def new_lines
        @new_lines ||= begin
          lines = self.class.process_file(diff_repository, diff_new_ref, diff_new_path)
          lines.map! { |line| " #{line}" }
        end
      end
    end
  end
end
