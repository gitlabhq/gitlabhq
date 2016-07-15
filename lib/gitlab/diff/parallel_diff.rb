module Gitlab
  module Diff
    class ParallelDiff
      attr_accessor :diff_file

      def initialize(diff_file)
        @diff_file = diff_file
      end

      def parallelize

        i = 0
        free_right_index = nil

        lines = []
        highlighted_diff_lines = diff_file.highlighted_diff_lines
        highlighted_diff_lines.each do |line|
          line_code = diff_file.line_code(line)
          position = diff_file.position(line)

          case line.type
          when 'match', nil
            # line in the right panel is the same as in the left one
            lines << {
              left: {
                type:       line.type,
                number:     line.old_pos,
                text:       line.text,
                line_code:  line_code,
                position:   position
              },
              right: {
                type:       line.type,
                number:     line.new_pos,
                text:       line.text,
                line_code:  line_code,
                position:   position
              }
            }

            free_right_index = nil
            i += 1
          when 'old'
            lines << {
              left: {
                type:       line.type,
                number:     line.old_pos,
                text:       line.text,
                line_code:  line_code,
                position:   position
              },
              right: {
                type:       nil,
                number:     nil,
                text:       "",
                line_code:  line_code,
                position:   position
              }
            }

            # Once we come upon a new line it can be put on the right of this old line
            free_right_index ||= i
            i += 1
          when 'new'
            data = {
              type:       line.type,
              number:     line.new_pos,
              text:       line.text,
              line_code:  line_code,
              position:   position
            }

            if free_right_index
              # If an old line came before this without a line on the right, this
              # line can be put to the right of it.
              lines[free_right_index][:right] = data

              # If there are any other old lines on the left that don't yet have
              # a new counterpart on the right, update the free_right_index
              next_free_right_index = free_right_index + 1
              free_right_index = next_free_right_index < i ? next_free_right_index : nil
            else
              lines << {
                left: {
                  type:       nil,
                  number:     nil,
                  text:       "",
                  line_code:  line_code,
                  position:   position
                },
                right: data
              }

              free_right_index = nil
              i += 1
            end
          end
        end

        lines
      end
    end
  end
end
