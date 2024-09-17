# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class ParallelHunkComponent < DiffHunkComponent
        def line_count_between
          prev = @diff_hunk[:prev]
          return 0 if !prev || @diff_hunk[:lines].empty? || prev[:lines].empty?

          first_pair = @diff_hunk[:lines].first
          first_line = first_pair[:left] || first_pair[:right]
          prev_pair = prev[:lines].last
          prev_line = prev_pair[:left] || prev_pair[:right]
          first_line.old_pos - prev_line.old_pos
        end
      end
    end
  end
end
