# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class ParallelHunkComponent < ViewComponent::Base
        def initialize(diff_hunk:, diff_file:)
          @diff_hunk = diff_hunk
          @diff_file = diff_file
        end

        def sides(line_pair)
          [
            {
              line: line_pair[:left],
              position: :old,
              border: :right
            },
            {
              line: line_pair[:right],
              position: :new,
              border: :both
            }
          ]
        end
      end
    end
  end
end
