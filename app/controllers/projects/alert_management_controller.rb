# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  before_action :authorize_read_alert_management_alert!

  before_action(only: [:index]) do
    push_frontend_feature_flag(:managed_alerts_deprecation, @project, default_enabled: :yaml)
  end

  feature_category :incident_management

  def index
  end

  def details
    @alert_id = params[:id]
  end
end
