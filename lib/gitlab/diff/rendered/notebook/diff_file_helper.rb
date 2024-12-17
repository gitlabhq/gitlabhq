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

          # line_positions_at_source_diff: given the transformed lines,
          # what are the correct values for old_pos and new_pos?
          #
          # Example:
          #
          # Original
          # from | to
          # A    | A
          # B    | D
          # C    | E
          # F    | F
          #
          # Original Diff
          #   A A
          # - B
          # - C
          # +   D
          # +   E
          #   F F
          #
          # Transformed
          # from | to
          # A    | A
          # C    | D
          # B    | J
          # L    | E
          # K    | K
          # F    | F
          #
          # Transformed diff | transf old, new | OG old_pos, new_pos |
          #  A A             | 1, 1            | 1, 1                |
          # -C               | 2, 2            | 3, 2                |
          # -B               | 3, 2            | 2, 2                |
          # -L               | 4, 2            | 0, 0                |
          # +  D             | 5, 2            | 4, 2                |
          # +  J             | 5, 3            | 0, 0                |
          # +  E             | 5, 4            | 4, 3                |
          #  K K             | 5, 5            | 0, 0                |
          #  F F             | 6, 6            | 4, 4                |
          def line_positions_at_source_diff(lines, blocks)
            last_mapped_old_pos = 0
            last_mapped_new_pos = 0

            lines.reverse_each.map do |line|
              old_pos = source_line_from_block(line.old_pos, blocks[:from])
              new_pos = source_line_from_block(line.new_pos, blocks[:to])

              old_has_no_mapping = old_pos == 0
              new_has_no_mapping = new_pos == 0

              next [0, 0] if old_has_no_mapping && (new_has_no_mapping || line.type == 'old')
              next [0, 0] if new_has_no_mapping && line.type == 'new'

              new_pos = last_mapped_new_pos if new_has_no_mapping && line.type == 'old'
              old_pos = last_mapped_old_pos if old_has_no_mapping && line.type == 'new'

              last_mapped_old_pos = old_pos
              last_mapped_new_pos = new_pos

              [old_pos, new_pos]
            end.reverse
          end

          def lines_in_source_diff(source_diff_lines, is_deleted_file, is_added_file)
            {
              from: is_added_file ? Set[] : source_diff_lines.map { |l| l.old_pos }.to_set,
              to: is_deleted_file ? Set[] : source_diff_lines.map { |l| l.new_pos }.to_set
            }
          end

          def source_line_from_block(transformed_line, transformed_blocks)
            # Blocks are the lines returned from the library and are a hash with {text:, source_line:}
            # Blocks source_line are 0 indexed
            return 0 if transformed_blocks.empty?

            line_in_source = transformed_blocks[transformed_line - 1][:source_line]

            return 0 unless line_in_source.present?

            line_in_source
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
