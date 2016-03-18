module Gitlab
  module Diff
    class Highlight
      attr_reader :diff_file, :diff_lines, :raw_lines

      delegate :old_path, :new_path, :old_ref, :new_ref, to: :diff_file, prefix: :diff

      def initialize(diff_lines)
        if diff_lines.is_a?(Gitlab::Diff::File)
          @diff_file = diff_lines
          @diff_lines = @diff_file.diff_lines
        else
          @diff_lines = diff_lines
        end
        @raw_lines = @diff_lines.map(&:text)
      end

      def highlight
        @diff_lines.map.with_index do |diff_line, i|
          diff_line = diff_line.dup
          # ignore highlighting for "match" lines
          next diff_line if diff_line.type == 'match' || diff_line.type == 'nonewline'

          rich_line = highlight_line(diff_line) || diff_line.text

          if line_inline_diffs = inline_diffs[i]
            rich_line = InlineDiffMarker.new(diff_line.text, rich_line).mark(line_inline_diffs)
          end

          diff_line.text = rich_line

          diff_line
        end
      end

      private

      def highlight_line(diff_line)
        return unless diff_file && diff_file.diff_refs

        line_prefix = diff_line.text.match(/\A(.)/) ? $1 : ' '

        case diff_line.type
        when 'new', nil
          rich_line = new_lines[diff_line.new_pos - 1]
        when 'old'
          rich_line = old_lines[diff_line.old_pos - 1]
        end

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        "#{line_prefix}#{rich_line}".html_safe if rich_line
      end

      def inline_diffs
        @inline_diffs ||= InlineDiff.for_lines(@raw_lines)
      end

      def old_lines
        return unless diff_file
        @old_lines ||= Gitlab::Highlight.highlight_lines(*processing_args(:old))
      end

      def new_lines
        return unless diff_file
        @new_lines ||= Gitlab::Highlight.highlight_lines(*processing_args(:new))
      end

      def processing_args(version)
        ref  = send("diff_#{version}_ref")
        path = send("diff_#{version}_path")

        [ref.project.repository, ref.id, path]
      end
    end
  end
end
