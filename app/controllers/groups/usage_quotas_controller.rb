# frozen_string_literal: true

module Groups
  class UsageQuotasController < Groups::ApplicationController
    before_action :authorize_read_usage_quotas!
    before_action :verify_usage_quotas_enabled!

    feature_category :subscription_usage_reports
    urgency :low

    def index
      # To be used in ee/app/controllers/ee/groups/usage_quotas_controller.rb
      @seat_count_data = seat_count_data
      @current_namespace_usage = current_namespace_usage
      @projects_usage = projects_usage
    end

    private

    def verify_usage_quotas_enabled!
      render_404 unless Feature.enabled?(:usage_quotas_for_all_editions, group)
      render_404 if group.has_parent?
    end

    # To be overriden in ee/app/controllers/ee/groups/usage_quotas_controller.rb
    def seat_count_data; end

    def current_namespace_usage; end

    def projects_usage; end
  end
end

Groups::UsageQuotasController.prepend_mod
