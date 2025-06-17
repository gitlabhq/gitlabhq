# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  include IncidentManagementFeatureFlag

  before_action :authorize_read_alert_management_alert!
  before_action :check_incidents_feature_flag, only: [:index, :details]

  feature_category :incident_management
  urgency :low

  def index; end

  def details
    @alert_id = params[:id]
  end
end
