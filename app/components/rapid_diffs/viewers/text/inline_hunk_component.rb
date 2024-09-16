# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineHunkComponent < DiffHunkComponent
        def line_count_between
          prev = @diff_hunk[:prev]
          return 0 if !prev || @diff_hunk[:lines].empty? || prev[:lines].empty?

          @diff_hunk[:lines].first.old_pos - prev[:lines].last.old_pos
        end
      end
    end
  end
end
