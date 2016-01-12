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
        update_diff_lines
      end

      private

      def text_lines
        @text_lines ||= @lines.map(&:text)
      end

      def extract_line_prefixes
        @diff_line_prefixes ||= text_lines.map { |line| line.sub!(/\A((\+|\-))/, '');$1 }
      end

      def update_diff_lines
        @lines.each_with_index do |line, i|
          line_prefix = @diff_line_prefixes[i] || ' '

          # ignore highlighting for "match" lines
          next if line.type == 'match'

          case line.type
          when 'new', nil
            highlighted_line = new_lines[line.new_pos - 1]
          when 'old'
            highlighted_line = old_lines[line.old_pos - 1]
          end

          # Only update text if line is found. This will prevent
          # issues with submodules given the line only exists in diff content.
          line.text = highlighted_line.gsub!(/\A\s/, line_prefix) if line
        end

        @lines
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
