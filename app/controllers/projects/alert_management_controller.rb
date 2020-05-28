# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  before_action :authorize_read_alert_management_alert!
  before_action do
    push_frontend_feature_flag(:alert_assignee, project)
  end

  def index
  end

  def details
    @alert_id = params[:id]
  end
end
