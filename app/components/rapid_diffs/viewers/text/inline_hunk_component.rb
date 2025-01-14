# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineHunkComponent < ViewComponent::Base
        def initialize(diff_hunk:, file_hash:, file_path:)
          @diff_hunk = diff_hunk
          @file_hash = file_hash
          @file_path = file_path
        end
      end
    end
  end
end
