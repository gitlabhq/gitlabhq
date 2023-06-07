# frozen_string_literal: true

module Gitlab
  module Diff
    class PositionTracer
      class FileStrategy < BaseStrategy
        def trace(position)
          a_path = position.old_path
          b_path = position.new_path

          # If file exists in B->D (e.g. updated, renamed, removed), let the
          # note become outdated.
          bd_diff = bd_diffs.diff_file_with_old_path(b_path)

          return { position: new_position(position, bd_diff), outdated: true } if bd_diff

          # If file still exists in the new diff, update the position.
          cd_diff = cd_diffs.diff_file_with_new_path(b_path)

          return { position: new_position(position, cd_diff), outdated: false } if cd_diff

          # If file exists in A->C (e.g. rebased and same changes were present
          # in target branch), let the note become outdated.
          ac_diff = ac_diffs.diff_file_with_old_path(a_path)

          return { position: new_position(position, ac_diff), outdated: true } if ac_diff

          # If ever there's a case that the file no longer exists in any diff,
          # don't set a change position and let the note become outdated.
          #
          # This should never happen given the file should exist in one of the
          # diffs above.
          { outdated: true }
        end

        private

        def new_position(position, diff_file)
          Position.new(
            diff_file: diff_file,
            position_type: position.position_type
          )
        end
      end
    end
  end
end
