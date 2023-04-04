# frozen_string_literal: true

module Projects
  class UsageQuotasController < Projects::ApplicationController
    before_action :authorize_read_usage_quotas!

    layout "project_settings"

    before_action do
      push_frontend_feature_flag(:move_year_dropdown_usage_charts, current_user)
    end

    feature_category :consumables_cost_management
    urgency :low

    def index
      @hide_search_settings = true
    end
  end
end

Projects::UsageQuotasController.prepend_mod
