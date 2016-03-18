module Gitlab
  module Diff
    class File
      attr_reader :diff, :diff_refs

      delegate :new_file, :deleted_file, :renamed_file,
        :old_path, :new_path, to: :diff, prefix: false

      def initialize(diff, diff_refs)
        @diff = diff
        @diff_refs = diff_refs
      end

      def old_ref
        diff_refs[0] if diff_refs
      end

      def new_ref
        diff_refs[1] if diff_refs
      end

      # Array of Gitlab::DIff::Line objects
      def diff_lines
        @lines ||= parser.parse(raw_diff.each_line).to_a
      end

      def highlighted_diff_lines
        Gitlab::Diff::Highlight.new(self).highlight
      end

      def parallel_diff_lines
        Gitlab::Diff::ParallelDiff.new(self).parallelize
      end

      def mode_changed?
        !!(diff.a_mode && diff.b_mode && diff.a_mode != diff.b_mode)
      end

      def parser
        Gitlab::Diff::Parser.new
      end

      def raw_diff
        diff.diff.to_s
      end

      def next_line(index)
        diff_lines[index + 1]
      end

      def prev_line(index)
        if index > 0
          diff_lines[index - 1]
        end
      end

      def file_path
        if diff.new_path.present?
          diff.new_path
        elsif diff.old_path.present?
          diff.old_path
        end
      end

      def added_lines
        diff_lines.count(&:added?)
      end

      def removed_lines
        diff_lines.count(&:removed?)
      end
    end
  end
end
