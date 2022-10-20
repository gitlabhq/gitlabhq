# frozen_string_literal: true

class Projects::UsageQuotasController < Projects::ApplicationController
  before_action :authorize_read_usage_quotas!

  layout "project_settings"

  feature_category :subscription_cost_management
  urgency :low

  def index
    @hide_search_settings = true
  end
end
