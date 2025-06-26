# frozen_string_literal: true

module HomepageData
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  private

  def homepage_app_data(user)
    {
      review_requested_path: review_requested_path(user),
      assigned_to_you_path: assigned_to_you_path(user),
      duo_code_review_bot_username: duo_code_review_bot.username
    }
  end

  def review_requested_path(user)
    return merge_requests_dashboard_path if Feature.enabled?(:merge_request_dashboard, user)

    merge_requests_dashboard_path(reviewer_username: user.username)
  end

  def assigned_to_you_path(user)
    return merge_requests_dashboard_path if Feature.enabled?(:merge_request_dashboard, user)

    merge_requests_dashboard_path(assignee_username: user.username)
  end

  def duo_code_review_bot
    ::Users::Internal.duo_code_review_bot
  end
  strong_memoize_attr :duo_code_review_bot
end
