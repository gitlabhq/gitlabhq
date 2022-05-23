# frozen_string_literal: true

class Projects::UsageQuotasController < Projects::ApplicationController
  before_action :authorize_read_usage_quotas!

  before_action do
    push_frontend_feature_flag(:container_registry_project_statistics, project)
  end

  layout "project_settings"

  feature_category :utilization
  urgency :low

  def index
    @hide_search_settings = true
  end
end
