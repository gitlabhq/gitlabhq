module Gitlab
  module Diff
    class ParallelDiff
      attr_accessor :diff_file

      def initialize(diff_file)
        @diff_file = diff_file
      end

      def parallelize
        lines = []
        skip_next = false

        highlighted_diff_lines = diff_file.highlighted_diff_lines
        highlighted_diff_lines.each do |line|
          full_line = line.text
          type = line.type
          line_code = generate_line_code(diff_file.file_path, line)
          line_new = line.new_pos
          line_old = line.old_pos

          next_line = diff_file.next_line(line.index)

          if next_line
            next_line = highlighted_diff_lines[next_line.index]
            next_line_code = generate_line_code(diff_file.file_path, next_line)
            next_type = next_line.type
            next_line = next_line.text
          end

          case type
          when 'match', nil
            # line in the right panel is the same as in the left one
            lines << {
              left: {
                type:       type,
                number:     line_old,
                text:       full_line,
                line_code:  line_code,
              },
              right: {
                type:       type,
                number:     line_new,
                text:       full_line,
                line_code:  line_code
              }
            }
          when 'old'
            case next_type
            when 'new'
              # Left side has text removed, right side has text added
              lines << {
                left: {
                  type:       type,
                  number:     line_old,
                  text:       full_line,
                  line_code:  line_code,
                },
                right: {
                  type:       next_type,
                  number:     line_new,
                  text:       next_line,
                  line_code:  next_line_code
                }
              }
              skip_next = true
            when 'old', 'nonewline', nil
              # Left side has text removed, right side doesn't have any change
              # No next line code, no new line number, no new line text
              lines << {
                left: {
                  type:       type,
                  number:     line_old,
                  text:       full_line,
                  line_code:  line_code,
                },
                right: {
                  type:       next_type,
                  number:     nil,
                  text:       "",
                  line_code:  nil
                }
              }
            end
          when 'new'
            if skip_next
              # Change has been already included in previous line so no need to do it again
              skip_next = false
              next
            else
              # Change is only on the right side, left side has no change
              lines << {
                left: {
                  type:       nil,
                  number:     nil,
                  text:       "",
                  line_code:  line_code,
                },
                right: {
                  type:       type,
                  number:     line_new,
                  text:       full_line,
                  line_code:  line_code
                }
              }
            end
          end
        end
        lines
      end

      private

      def generate_line_code(file_path, line)
        Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
      end
    end
  end
end
