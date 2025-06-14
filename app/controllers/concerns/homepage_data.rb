# frozen_string_literal: true

module HomepageData
  extend ActiveSupport::Concern

  private

  def homepage_app_data(user)
    {
      review_requested_path: merge_requests_dashboard_path(reviewer_username: user.username),
      assigned_to_you_path: merge_requests_dashboard_path(assignee_username: user.username)
    }
  end
end
