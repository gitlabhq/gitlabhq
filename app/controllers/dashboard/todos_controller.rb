# frozen_string_literal: true

class Dashboard::TodosController < Dashboard::ApplicationController
  include Gitlab::InternalEventsTracking

  feature_category :notifications
  urgency :low

  def index
    track_internal_event(
      'view_todo_list',
      user: current_user
    )

    push_frontend_feature_flag(:todos_bulk_actions, current_user)
  end
end
