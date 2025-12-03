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

        def id(line)
          line.id(@file_hash)
        end

        def line_pairs
          @diff_hunk.parallel_lines.map do |pair|
            {
              line_id: id(pair[:left] || pair[:right]),
              sides: [
                {
                  line: pair[:left],
                  position: :old
                },
                {
                  line: pair[:right],
                  position: :new
                }
              ],
              expanded: pair[:left]&.expanded? || pair[:right]&.expanded?
            }
          end
        end
      end
    end
  end
end
