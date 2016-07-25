module Gitlab
  module Conflict
    class Parser
      class UnexpectedDelimiter < StandardError
      end

      class MissingEndDelimiter < StandardError
      end

      def parse(text, their_path, our_path)
        return [] if text.blank?

        line_obj_index = 0
        line_old = 1
        line_new = 1
        type = nil
        lines = []
        conflict_start = "<<<<<<< #{our_path}"
        conflict_middle = '======='
        conflict_end = ">>>>>>> #{their_path}"

        text.each_line.map do |line|
          full_line = line.delete("\n")

          if full_line == conflict_start
            raise UnexpectedDelimiter unless type.nil?

            type = 'new'
          elsif full_line == conflict_middle
            raise UnexpectedDelimiter unless type == 'new'

            type = 'old'
          elsif full_line == conflict_end
            raise UnexpectedDelimiter unless type == 'old'

            type = nil
          elsif line[0] == '\\'
            type = 'nonewline'
            lines << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
          else
            lines << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
            line_old += 1 if type != 'new'
            line_new += 1 if type != 'old'

            line_obj_index += 1
          end
        end

        raise MissingEndDelimiter unless type == nil

        lines
      end

      def empty?
        @lines.empty?
      end
    end
  end
end
