# frozen_string_literal: true

module WithPerformanceBar
  extend ActiveSupport::Concern

  included do
    before_action :set_peek_enabled_for_current_request
  end

  private

  def set_peek_enabled_for_current_request
    Gitlab::SafeRequestStore.fetch(:peek_enabled) { cookie_or_default_value }
  end

  # Needed for Peek's routing to work;
  # Peek::ResultsController#restrict_non_access calls this method.
  def peek_enabled?
    Gitlab::PerformanceBar.enabled_for_request?
  end

  def cookie_or_default_value
    cookies[:perf_bar_enabled] = 'true' if cookies[:perf_bar_enabled].blank? && Rails.env.development?

    cookie_enabled = cookies[:perf_bar_enabled] == 'true'
    cookie_enabled && Gitlab::PerformanceBar.allowed_for_user?(current_user)
  end
end
