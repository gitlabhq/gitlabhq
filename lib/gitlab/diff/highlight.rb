# frozen_string_literal: true

module Gitlab
  module Diff
    class Highlight
      PREFIX_REGEXP = /\A(.)/

      attr_reader :diff_file, :diff_lines, :repository, :project

      delegate :old_path, :new_path, :old_sha, :new_sha, to: :diff_file, prefix: :diff

      def initialize(diff_lines, repository: nil, plain: false)
        @repository = repository
        @project = repository&.project
        @plain = plain

        if diff_lines.is_a?(Gitlab::Diff::File)
          @diff_file = diff_lines
          @diff_lines = @diff_file.diff_lines
        else
          @diff_lines = diff_lines
        end

        @raw_lines = @diff_lines.map(&:text)
      end

      def highlight
        populate_marker_ranges

        @diff_lines.map do |diff_line|
          diff_line = diff_line.dup
          # ignore highlighting for "match" lines
          next diff_line if diff_line.meta?

          rich_line = apply_syntax_highlight(diff_line)
          rich_line = apply_marker_ranges_highlight(diff_line, rich_line)

          diff_line.rich_text = rich_line

          diff_line
        end
      end

      private

      attr_reader :plain

      def populate_marker_ranges
        pair_selector = Gitlab::Diff::PairSelector.new(@raw_lines)

        pair_selector.each do |old_index, new_index|
          old_line = diff_lines[old_index]
          new_line = diff_lines[new_index]

          old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(old_line.text, new_line.text, offset: 1).inline_diffs

          old_line.set_marker_ranges(old_diffs)
          new_line.set_marker_ranges(new_diffs)
        end
      end

      def apply_syntax_highlight(diff_line)
        highlight_line(diff_line) || ERB::Util.html_escape(diff_line.text)
      end

      def apply_marker_ranges_highlight(diff_line, rich_line)
        marker_ranges = diff_line.marker_ranges

        return rich_line if marker_ranges.blank?

        begin
          InlineDiffMarker.new(diff_line.text, rich_line).mark(marker_ranges)
        # This should only happen when the encoding of the diff doesn't
        # match the blob, which is a bug. But we shouldn't fail to render
        # completely in that case, even though we want to report the error.
        rescue RangeError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/45441')
        end
      end

      def highlight_line(diff_line)
        return unless diff_file && diff_file.diff_refs
        return diff_line_highlighting(diff_line, plain: true) if blobs_too_large? || plain

        if Feature.enabled?(:diff_line_syntax_highlighting, project)
          diff_line_highlighting(diff_line)
        else
          blob_highlighting(diff_line)
        end
      end

      def diff_line_highlighting(diff_line, plain: false)
        rich_line = syntax_highlighter(diff_line).highlight(
          diff_line.text(prefix: false),
          plain: plain,
          context: { line_number: diff_line.line },
          used_on: :diff
        )

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        if rich_line
          line_prefix = diff_line.text =~ PREFIX_REGEXP ? Regexp.last_match(1) : ' '
          rich_line.prepend(line_prefix).concat("\n")
        end
      end

      def syntax_highlighter(diff_line)
        path = diff_line.removed? ? diff_file.old_path : diff_file.new_path

        @syntax_highlighter ||= {}
        @syntax_highlighter[path] ||= Gitlab::Highlight.new(
          path,
          @raw_lines,
          language: repository&.gitattribute(path, 'gitlab-language')
        )
      end

      # Deprecated: https://gitlab.com/gitlab-org/gitlab/-/issues/324159
      # ------------------------------------------------------------------------
      def blob_highlighting(diff_line)
        rich_line =
          if diff_line.unchanged? || diff_line.added?
            new_lines[diff_line.new_pos - 1]&.html_safe
          elsif diff_line.removed?
            old_lines[diff_line.old_pos - 1]&.html_safe
          end

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        if rich_line
          line_prefix = diff_line.text =~ PREFIX_REGEXP ? Regexp.last_match(1) : ' '
          "#{line_prefix}#{rich_line}".html_safe
        end
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

        blob.present.highlight(used_on: :diff).lines
      end

      def blobs_too_large?
        return true if Gitlab::Highlight.too_large?(diff_file.old_blob&.size)

        Gitlab::Highlight.too_large?(diff_file.new_blob&.size)
      end
    end
  end
end
