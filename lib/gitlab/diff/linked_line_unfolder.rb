# frozen_string_literal: true

module Gitlab
  module Diff
    class LinkedLineUnfolder
      def self.from_param(line_id)
        parsed = Gitlab::Diff::Line.parse_id(line_id)
        return unless parsed
        return if parsed[:added]

        new(old_line: parsed[:line])
      end

      def initialize(old_line:)
        @old_line = old_line
      end

      def unfold!(diff_file)
        diff_file.unfold_diff_lines(position(diff_file))
      end

      private

      def position(diff_file)
        Gitlab::Diff::Position.new(
          position_type: 'text',
          old_path: diff_file.old_path,
          new_path: diff_file.new_path,
          old_line: @old_line,
          new_line: @old_line
        )
      end
    end
  end
end
