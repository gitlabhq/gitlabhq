# frozen_string_literal: true

module Projects
  module IssuesHelper
    def create_mr_tracking_data(can_create_mr, can_create_confidential_mr)
      if can_create_confidential_mr
        { event_tracking: 'click_create_confidential_mr_issues_list' }
      elsif can_create_mr
        { event_tracking: 'click_create_mr_issues_list' }
      else
        {}
      end
    end
  end
end
