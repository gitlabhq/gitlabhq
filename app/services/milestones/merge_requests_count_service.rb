# frozen_string_literal: true

module Milestones
  class MergeRequestsCountService < BaseCountService
    def initialize(milestone)
      @milestone = milestone
    end

    def cache_key
      "milestone_merge_requests_count_#{@milestone.milestoneish_id}"
    end

    def relation_for_count
      @milestone.merge_requests
    end
  end
end
