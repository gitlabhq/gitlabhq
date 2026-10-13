# frozen_string_literal: true

module HomepageData
  extend ActiveSupport::Concern
  include MergeRequestsHelper

  private

  def homepage_app_data(user)
    last_push_event = user&.recent_push

    {
      activity_path: activity_dashboard_path,
      last_push_event: prepare_last_push_event_data(last_push_event)&.to_json
    }
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
end
