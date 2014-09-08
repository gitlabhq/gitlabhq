module Gitlab
  module Diff
    class File
      attr_reader :diff, :blob

      delegate :new_file, :deleted_file, :renamed_file,
        :old_path, :new_path, to: :diff, prefix: false

      def initialize(project, commit, diff)
        @diff = diff
        @blob = project.repository.blob_for_diff(commit, diff)
      end

      # Array of Gitlab::DIff::Line objects
      def diff_lines
        @lines ||= parser.parse(diff.diff.lines, old_path, new_path)
      end

      def blob_exists?
        !@blob.nil?
      end

      def mode_changed?
        diff.a_mode && diff.b_mode && diff.a_mode != diff.b_mode
      end

      def parser
        Gitlab::Diff::Parser.new
      end

      def next_line(index)
        diff_lines[index + 1]
      end

      def prev_line(index)
        if index > 0
          diff_lines[index - 1]
        end
      end
    end
  end
end
