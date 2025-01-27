# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineHunkComponent < ViewComponent::Base
        with_collection_parameter :diff_hunk

        def initialize(diff_hunk:, file_hash:, file_path:)
          @diff_hunk = diff_hunk
          @file_hash = file_hash
          @file_path = file_path
        end

        def testid
          'hunk-lines-inline'
        end
      end
    end
  end
end
