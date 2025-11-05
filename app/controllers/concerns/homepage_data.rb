# frozen_string_literal: true

module HomepageData
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include MergeRequestsHelper

  private

  def homepage_app_data(user)
    mr_requested_id, mr_requests_id = merge_request_ids(user)
    last_push_event = user&.recent_push

    {
      review_requested_path: merge_requests_dashboard_path,
      activity_path: activity_dashboard_path,
      assigned_merge_requests_path: merge_requests_dashboard_path,
      assigned_work_items_path: issues_dashboard_path(assignee_username: user.username),
      authored_work_items_path: issues_dashboard_path(author_username: user.username),
      duo_code_review_bot_username: duo_code_review_bot.username,
      merge_requests_review_requested_title: dashboard_list_title(mr_requested_id),
      merge_requests_your_merge_requests_title: dashboard_list_title(mr_requests_id),
      last_push_event: prepare_last_push_event_data(last_push_event)&.to_json,
      show_feedback_widget: show_feedback_widget?.to_s
    }
  end

  def show_feedback_widget?
    return true unless Gitlab.ee?

    !License.current&.offline_cloud_license?
  end

  def prepare_last_push_event_data(last_push_event)
    return unless last_push_event

    event_data = {
      id: last_push_event.id,
      created_at: last_push_event.created_at,
      ref_name: last_push_event.ref_name,
      branch_name: last_push_event.branch_name,
      show_widget: helpers.show_last_push_widget?(last_push_event)
    }

    if last_push_event.project
      project = last_push_event.project
      event_data[:project] = {
        name: project.name,
        web_url: project.web_url
      }
    end

    # Use the same logic as HAML version for create MR button
    event_data[:create_mr_path] = if create_mr_button_from_event?(last_push_event)
                                    create_mr_path_from_push_event(last_push_event)
                                  else
                                    ''
                                  end

    event_data
  end

  def merge_request_ids(user)
    if user.user_preference.role_based?
      %w[reviews assigned]
    else
      %w[reviews_requested assigned_to_you]
    end
  end

  def duo_code_review_bot
    ::Users::Internal.duo_code_review_bot
  end
  strong_memoize_attr :duo_code_review_bot
end
