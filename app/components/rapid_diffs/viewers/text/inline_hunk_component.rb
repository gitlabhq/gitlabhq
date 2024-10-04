# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineHunkComponent < ViewComponent::Base
        def initialize(diff_hunk:, diff_file:)
          @diff_hunk = diff_hunk
          @diff_file = diff_file
        end
      end
    end
  end
end
