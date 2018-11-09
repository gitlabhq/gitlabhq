# frozen_string_literal: true

# When provided a diff for a specific file, maps old line numbers to new line
# numbers and back, to find out where a specific line in a file was moved by the
# changes.
module Gitlab
  module Diff
    class LineMapper
      attr_accessor :diff_file

      def initialize(diff_file)
        @diff_file = diff_file
      end

      # Find new line number for old line number.
      def old_to_new(old_line)
        map_line_number(old_line, from: :old_line, to: :new_line)
      end

      # Find old line number for new line number.
      def new_to_old(new_line)
        map_line_number(new_line, from: :new_line, to: :old_line)
      end

      private

      def diff_lines
        @diff_lines ||= @diff_file.diff_lines
      end

      # Find old/new line number based on its old/new counterpart line number.
      def map_line_number(from_line, from:, to:)
        # If no diff file could be found, the file wasn't changed, and the
        # mapped line number is the same as the specified line number.
        return from_line unless diff_file

        # To find the mapped line number for the specified line number,
        # we need to find:
        # - The diff line with that exact line number, if it is in the diff context
        # - The first diff line with a higher line number, if it falls between diff contexts
        # - The last known diff line, if it falls after the last diff context
        diff_line = diff_lines.find do |diff_line|
          diff_from_line = diff_line.public_send(from) # rubocop:disable GitlabSecurity/PublicSend
          diff_from_line && diff_from_line >= from_line
        end
        diff_line ||= diff_lines.last

        # If no diff line could be found, the file wasn't changed, and the
        # mapped line number is the same as the specified line number.
        return from_line unless diff_line

        diff_from_line = diff_line.public_send(from) # rubocop:disable GitlabSecurity/PublicSend
        diff_to_line = diff_line.public_send(to) # rubocop:disable GitlabSecurity/PublicSend

        # If the line was removed, there is no mapped line number.
        return unless diff_to_line

        # Because we may not have the diff line with the exact line number
        # we were looking for, we need to adjust the mapped line number.
        distance = diff_from_line - from_line

        diff_to_line - distance
      end
    end
  end
end
