module Gitlab
  module Diff
    class File
      attr_reader :diff

      delegate :new_file, :deleted_file, :renamed_file,
        :old_path, :new_path, to: :diff, prefix: false

      def initialize(diff)
        @diff = diff
      end

      # Array of Gitlab::DIff::Line objects
      def diff_lines
        @lines ||= parser.parse(raw_diff.lines)
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
        diff_lines.select(&:added?).size
      end

      def removed_lines
        diff_lines.select(&:removed?).size
      end
    end
  end
end
