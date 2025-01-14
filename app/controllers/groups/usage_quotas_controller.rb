# frozen_string_literal: true

module Groups
  class UsageQuotasController < Groups::ApplicationController
    before_action :authorize_read_usage_quotas!
    before_action :verify_usage_quotas_enabled!

    before_action do
      push_frontend_feature_flag(:virtual_registry_maven, current_user)
    end

    feature_category :consumables_cost_management
    urgency :low

    def index
      # To be used in ee/app/controllers/ee/groups/usage_quotas_controller.rb
      @seat_count_data = seat_count_data
    end

    private

    def verify_usage_quotas_enabled!
      render_404 unless group.usage_quotas_enabled?
    end

    # To be overridden in ee/app/controllers/ee/groups/usage_quotas_controller.rb
    def seat_count_data; end
  end
end

Groups::UsageQuotasController.prepend_mod
