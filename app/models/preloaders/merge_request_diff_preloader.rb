# frozen_string_literal: true

module Preloaders
  # This class preloads the `merge_request_diff` association for the given merge request models.
  #
  # Usage:
  #   merge_requests = MergeRequest.where(...)
  #   Preloaders::MergeRequestDiffPreloader.new(merge_requests).preload_all
  #   merge_requests.first.merge_request_diff # won't fire any query
  class MergeRequestDiffPreloader
    def initialize(merge_requests)
      @merge_requests = merge_requests
    end

    def preload_all
      merge_request_diffs = MergeRequestDiff.latest_diff_for_merge_requests(@merge_requests)
      cache = merge_request_diffs.index_by { |diff| diff.merge_request_id }

      @merge_requests.each do |merge_request|
        merge_request_diff = cache[merge_request.id]

        merge_request.association(:merge_request_diff).target = merge_request_diff
        merge_request.association(:merge_request_diff).loaded!
      end
    end
  end
end
