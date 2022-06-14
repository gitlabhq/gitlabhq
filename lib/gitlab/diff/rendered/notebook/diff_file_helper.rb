# frozen_string_literal: true
module Gitlab
  module Diff
    module Rendered
      module Notebook
        module DiffFileHelper
          EMBEDDED_IMAGE_PATTERN = '    ![](data:image'

          def strip_diff_frontmatter(diff_content)
            diff_content.scan(/.*\n/)[2..]&.join('') if diff_content.present?
          end

          def map_transformed_line_to_source(transformed_line, transformed_blocks)
            transformed_blocks.empty? ? 0 : ( transformed_blocks[transformed_line - 1][:source_line] || -1 ) + 1
          end

          # line_codes are used for assigning notes to diffs, and these depend on the line on the new version and the
          # line that would have been that one in the previous version. However, since we do a transformation on the
          # file, that mapping gets lost. To overcome this, we look at the original source lines and build two maps:
          # - For additions, we look at the latest line change for that line and pick the old line for that id
          # - For removals, we look at the first line in the old version, and pick the first line on the new version
          #
          # Note: ipynb files never change the first or last line (open and closure of the
          # json object), unless the file is removed or deleted
          #
          # Example: Additions and removals
          # Old:   New:
          # A      A
          # B      D
          # C      E
          # F      F
          #
          # Diff:
          # 1  A A 1 | line code: 1_1
          # 2 -B     | line code: 2_2 -> new line is what it is after been without the removal, 2
          # 3 -C     | line code: 3_2
          #   +  D 2 | line code: 4_2 -> old line is what would have been before the addition, 4
          #   +  E 3 | line code: 4_3
          # 4 F  F 4 | line code: 4_4
          #
          # Example: only additions
          # Old:   New:
          # A      A
          # F      B
          #        C
          #        F
          #
          # Diff:
          #  A A | line code: 1_1
          # +  B | line code: 2_2 -> old line is the next after the additions, 2
          # +  C | line code: 2_3
          #  F F | line code: 2_4
          #
          # Example: only removals
          # Old:   New:
          # A      A
          # B      F
          # C
          # F
          #
          # Diff:
          #  A A | line code: 1_1
          # -B   | line code: 2_2 -> new line is what it is after been without the removal, 2
          # -C   | line code: 3_2
          #  F F | line code: 4_2
          def map_diff_block_to_source_line(lines, file_added, file_deleted)
            removals = {}
            additions = {}

            lines.each do |line|
              removals[line.old_pos] = line.new_pos unless file_added
              additions[line.new_pos] = line.old_pos unless file_deleted
            end

            [removals, additions]
          end

          def image_as_rich_text(line_text)
            return unless line_text[1..].starts_with?(EMBEDDED_IMAGE_PATTERN)

            image_body = line_text[1..].delete_prefix(EMBEDDED_IMAGE_PATTERN).delete_suffix(')')

            "<img src=\"data:image#{CGI.escapeHTML(image_body)}\">".html_safe
          end
        end
      end
    end
  end
end
