# frozen_string_literal: true

module Gitlab
  module Diff
    class ParallelDiff
      attr_accessor :diff_file

      def self.parallelize(diff_lines)
        i = 0
        free_right_index = nil

        lines = []
        diff_lines&.each do |line|
          if line.removed?
            lines << {
              left: line,
              right: nil
            }

            # Once we come upon a new line it can be put on the right of this old line
            free_right_index ||= i
            i += 1
          elsif line.added?
            if free_right_index
              # If an old line came before this without a line on the right, this
              # line can be put to the right of it.
              lines[free_right_index][:right] = line

              # If there are any other old lines on the left that don't yet have
              # a new counterpart on the right, update the free_right_index
              next_free_right_index = free_right_index + 1
              free_right_index = next_free_right_index < i ? next_free_right_index : nil
            else
              lines << {
                left: nil,
                right: line
              }

              free_right_index = nil
              i += 1
            end
          elsif line.meta? || line.unchanged? || !line.has_mapping_in_raw?
            # line in the right panel is the same as in the left one
            lines << {
              left: line,
              right: line
            }

            free_right_index = nil
            i += 1
          end
        end

        lines
      end

      def initialize(diff_file)
        @diff_file = diff_file
      end

      def parallelize
        self.class.parallelize(diff_file.highlighted_diff_lines)
      end
    end
  end
end
