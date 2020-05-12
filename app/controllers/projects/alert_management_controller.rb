# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  before_action :ensure_list_feature_enabled, only: :index
  before_action :ensure_detail_feature_enabled, only: :details
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

  private

  def ensure_list_feature_enabled
    render_404 unless Feature.enabled?(:alert_management_minimal, project)
  end

  def ensure_detail_feature_enabled
    render_404 unless Feature.enabled?(:alert_management_detail, project)
  end
end
