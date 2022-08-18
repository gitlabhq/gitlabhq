# frozen_string_literal: true

# Diff hunk is line that starts with @@
# It contains information about start line numbers
#
# Example:
# @@ -1,4 +1,5 @@
#
# See more: https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html
module Gitlab
  module WordDiff
    module Segments
      class DiffHunk
        def initialize(line)
          @line = line
        end

        def pos_old
          line.match(/\-[0-9]*/)[0].to_i.abs
        rescue StandardError
          0
        end

        def pos_new
          line.match(/\+[0-9]*/)[0].to_i.abs
        rescue StandardError
          0
        end

        def first_line?
          pos_old <= 1 && pos_new <= 1
        end

        def to_s
          line
        end

        private

        attr_reader :line
      end
    end
  end
end
