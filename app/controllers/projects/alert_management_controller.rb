# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  before_action :authorize_read_alert_management_alert!
  before_action do
    push_frontend_feature_flag(:alert_list_status_filtering_enabled)
    push_frontend_feature_flag(:create_issue_from_alert_enabled)
  end

  def index
  end

  def details
    @alert_id = params[:id]
  end
end
