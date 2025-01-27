# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class ParallelHunkComponent < ViewComponent::Base
        with_collection_parameter :diff_hunk

        def initialize(diff_hunk:, file_hash:, file_path:)
          @diff_hunk = diff_hunk
          @file_hash = file_hash
          @file_path = file_path
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

        def testid
          'hunk-lines-parallel'
        end
      end
    end
  end
end
