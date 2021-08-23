# frozen_string_literal: true

class Projects::UsageQuotasController < Projects::ApplicationController
  before_action :authorize_admin_project!
  before_action :verify_usage_quotas_enabled!

  layout "project_settings"

  feature_category :utilization

  private

  def verify_usage_quotas_enabled!
    render_404 unless Feature.enabled?(:project_storage_ui, project&.group, default_enabled: :yaml)
  end
end
