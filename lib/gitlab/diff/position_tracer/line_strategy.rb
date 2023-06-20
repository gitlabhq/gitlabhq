# frozen_string_literal: true

module Gitlab
  module Diff
    class PositionTracer
      class LineStrategy < BaseStrategy
        def trace(position)
          # Suppose we have an MR with source branch `feature` and target branch `master`.
          # When the MR was created, the head of `master` was commit A, and the
          # head of `feature` was commit B, resulting in the original diff A->B.
          # Since creation, `master` was updated to C.
          # Now `feature` is being updated to D, and the newly generated MR diff is C->D.
          # It is possible that C and D are direct descendants of A and B respectively,
          # but this isn't necessarily the case as rebases and merges come into play.
          #
          # Suppose we have a diff note on the original diff A->B. Now that the MR
          # is updated, we need to find out what line in C->D corresponds to the
          # line the note was originally created on, so that we can update the diff note's
          # records and continue to display it in the right place in the diffs.
          # If we cannot find this line in the new diff, this means the diff note is now
          # outdated, and we will display that fact to the user.
          #
          # In the new diff, the file the diff note was originally created on may
          # have been renamed, deleted or even created, if the file existed in A and B,
          # but was removed in C, and restored in D.
          #
          # Every diff note stores a Position object that defines a specific location,
          # identified by paths and line numbers, within a specific diff, identified
          # by start, head and base commit ids.
          #
          # For diff notes for diff A->B, the position looks like this:
          # Position
          #   start_sha - ID of commit A
          #   head_sha - ID of commit B
          #   base_sha - ID of base commit of A and B
          #   old_path - path as of A (nil if file was newly created)
          #   new_path - path as of B (nil if file was deleted)
          #   old_line - line number as of A (nil if file was newly created)
          #   new_line - line number as of B (nil if file was deleted)
          #
          # We can easily update `start_sha` and `head_sha` to hold the IDs of
          # commits C and D, and can trivially determine `base_sha` based on those,
          # but need to find the paths and line numbers as of C and D.
          #
          # If the file was unchanged or newly created in A->B, the path as of D can be found
          # by generating diff B->D ("head to head"), finding the diff file with
          # `diff_file.old_path == position.new_path`, and taking `diff_file.new_path`.
          # The path as of C can be found by taking diff C->D, finding the diff file
          # with that same `new_path` and taking `diff_file.old_path`.
          # The line number as of D can be found by using the LineMapper on diff B->D
          # and providing the line number as of B.
          # The line number as of C can be found by using the LineMapper on diff C->D
          # and providing the line number as of D.
          #
          # If the file was deleted in A->B, the path as of C can be found
          # by generating diff A->C ("base to base"), finding the diff file with
          # `diff_file.old_path == position.old_path`, and taking `diff_file.new_path`.
          # The path as of D can be found by taking diff C->D, finding the diff file
          # with `old_path` set to that `diff_file.new_path` and taking `diff_file.new_path`.
          # The line number as of C can be found by using the LineMapper on diff A->C
          # and providing the line number as of A.
          # The line number as of D can be found by using the LineMapper on diff C->D
          # and providing the line number as of C.

          @ignore_whitespace_change = position.ignore_whitespace_change

          if position.added?
            trace_added_line(position)
          elsif position.removed?
            trace_removed_line(position)
          else # unchanged
            trace_unchanged_line(position)
          end
        end

        private

        def trace_added_line(position)
          b_path = position.new_path
          b_line = position.new_line

          bd_diff = bd_diffs.diff_file_with_old_path(b_path)

          d_path = bd_diff&.new_path || b_path
          d_line = LineMapper.new(bd_diff).old_to_new(b_line)

          if d_line
            cd_diff = cd_diffs.diff_file_with_new_path(d_path)

            c_path = cd_diff&.old_path || d_path
            c_line = LineMapper.new(cd_diff).new_to_old(d_line)

            if c_line
              # If the line is still in D but also in C, it has turned from an
              # added line into an unchanged one.
              new_position = new_position(cd_diff, c_line, d_line, position.line_range)
              if valid_position?(new_position)
                # If the line is still in the MR, we don't treat this as outdated.
                { position: new_position, outdated: false }
              else
                # If the line is no longer in the MR, we unfortunately cannot show
                # the current state on the CD diff, so we treat it as outdated.
                ac_diff = ac_diffs.diff_file_with_new_path(c_path)

                { position: new_position(ac_diff, nil, c_line, position.line_range), outdated: true }
              end
            else
              # If the line is still in D and not in C, it is still added.
              { position: new_position(cd_diff, nil, d_line, position.line_range), outdated: false }
            end
          else
            # If the line is no longer in D, it has been removed from the MR.
            { position: new_position(bd_diff, b_line, nil, position.line_range), outdated: true }
          end
        end

        def trace_removed_line(position)
          a_path = position.old_path
          a_line = position.old_line

          ac_diff = ac_diffs.diff_file_with_old_path(a_path)

          c_path = ac_diff&.new_path || a_path
          c_line = LineMapper.new(ac_diff).old_to_new(a_line)

          if c_line
            cd_diff = cd_diffs.diff_file_with_old_path(c_path)

            d_path = cd_diff&.new_path || c_path
            d_line = LineMapper.new(cd_diff).old_to_new(c_line)

            if d_line
              # If the line is still in C but also in D, it has turned from a
              # removed line into an unchanged one.
              bd_diff = bd_diffs.diff_file_with_new_path(d_path)

              { position: new_position(bd_diff, nil, d_line, position.line_range), outdated: true }
            else
              # If the line is still in C and not in D, it is still removed.
              { position: new_position(cd_diff, c_line, nil, position.line_range), outdated: false }
            end
          else
            # If the line is no longer in C, it has been removed outside of the MR.
            { position: new_position(ac_diff, a_line, nil, position.line_range), outdated: true }
          end
        end

        def trace_unchanged_line(position)
          a_path = position.old_path
          a_line = position.old_line
          b_path = position.new_path
          b_line = position.new_line

          ac_diff = ac_diffs.diff_file_with_old_path(a_path)

          c_path = ac_diff&.new_path || a_path
          c_line = LineMapper.new(ac_diff).old_to_new(a_line)

          bd_diff = bd_diffs.diff_file_with_old_path(b_path)

          d_line = LineMapper.new(bd_diff).old_to_new(b_line)

          cd_diff = cd_diffs.diff_file_with_old_path(c_path)

          if c_line && d_line
            # If the line is still in C and D, it is still unchanged.
            new_position = new_position(cd_diff, c_line, d_line, position.line_range)
            if valid_position?(new_position)
              # If the line is still in the MR, we don't treat this as outdated.
              { position: new_position, outdated: false }
            else
              # If the line is no longer in the MR, we unfortunately cannot show
              # the current state on the CD diff or any change on the BD diff,
              # so we treat it as outdated.
              { position: nil, outdated: true }
            end
          elsif d_line # && !c_line
            # If the line is still in D but no longer in C, it has turned from
            # an unchanged line into an added one.
            # We don't treat this as outdated since the line is still in the MR.
            { position: new_position(cd_diff, nil, d_line, position.line_range), outdated: false }
          else # !d_line && (c_line || !c_line)
            # If the line is no longer in D, it has turned from an unchanged line
            # into a removed one.
            { position: new_position(bd_diff, b_line, nil), outdated: true }
          end
        end

        def new_position(diff_file, old_line, new_line, line_range = nil)
          params = {
            diff_file: diff_file,
            old_line: old_line,
            new_line: new_line,
            line_range: line_range,
            ignore_whitespace_change: @ignore_whitespace_change
          }.compact

          Position.new(**params)
        end

        def valid_position?(position)
          !!position.diff_line(project.repository)
        end
      end
    end
  end
end
