# frozen_string_literal: true

module Milestones
  class IssuesCountService < BaseCountService
    def initialize(milestone)
      @milestone = milestone
    end

    def cache_key
      "milestone_total_issues_count_#{@milestone.milestoneish_id}"
    end

    def relation_for_count
      @milestone.issues
    end
  end
end
