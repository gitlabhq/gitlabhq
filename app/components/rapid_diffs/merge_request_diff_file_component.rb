# frozen_string_literal: true

module RapidDiffs
  class MergeRequestDiffFileComponent < ViewComponent::Base
    with_collection_parameter :diff_file

    def initialize(diff_file:, merge_request:, parallel_view: false)
      @diff_file = diff_file
      @merge_request = merge_request
      @parallel_view = parallel_view
    end
  end
end
