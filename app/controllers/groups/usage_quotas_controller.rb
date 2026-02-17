# frozen_string_literal: true

module Groups
  class UsageQuotasController < Groups::ApplicationController
    before_action :authorize_read_usage_quotas!
    before_action :verify_usage_quotas_enabled!

    feature_category :consumables_cost_management, [:root]
    urgency :low

    def root
      render :root
    end

    private

    def verify_usage_quotas_enabled!
      render_404 unless group.usage_quotas_enabled?
    end
  end
end

Groups::UsageQuotasController.prepend_mod
