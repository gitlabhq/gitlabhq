module Gitlab
  module Diff
    class Highlight
      attr_reader :diff_file, :diff_lines, :raw_lines, :repository

      delegate :old_path, :new_path, :old_sha, :new_sha, to: :diff_file, prefix: :diff

      def initialize(diff_lines, since: nil, from: nil, repository: nil)
        @repository = repository

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
          next diff_line if diff_line.meta?

          rich_line = highlight_line(diff_line) || diff_line.text

          if line_inline_diffs = inline_diffs[i]
            begin
              rich_line = InlineDiffMarker.new(diff_line.text, rich_line).mark(line_inline_diffs)
            # This should only happen when the encoding of the diff doesn't
            # match the blob, which is a bug. But we shouldn't fail to render
            # completely in that case, even though we want to report the error.
            rescue RangeError => e
              if Gitlab::Sentry.enabled?
                Gitlab::Sentry.context
                Raven.capture_exception(e)
              end
            end
          end

          diff_line.text = rich_line

          diff_line
        end
      end

      private

      def highlight_line(diff_line)
        return unless diff_file && diff_file.diff_refs

        rich_line =
          if diff_line.unchanged? || diff_line.added?
            new_lines[diff_line.new_pos - 1]&.html_safe
          elsif diff_line.removed?
            old_lines[diff_line.old_pos - 1]&.html_safe
          end

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        if rich_line
          line_prefix = diff_line.text =~ /\A(.)/ ? $1 : ' '
          "#{line_prefix}#{rich_line}".html_safe
        end
      end

      def inline_diffs
        @inline_diffs ||= InlineDiff.for_lines(@raw_lines)
      end

      def old_lines
        @old_lines ||= highlighted_blob_lines(diff_file.old_blob)
      end

      def new_lines
        @new_lines ||= highlighted_blob_lines(diff_file.new_blob)
      end

      def highlighted_blob_lines(blob)
        return [] unless blob

        blob.load_all_data!
        Gitlab::Highlight.highlight(blob.path, blob.data, repository: repository).lines
      end
    end
  end
end
