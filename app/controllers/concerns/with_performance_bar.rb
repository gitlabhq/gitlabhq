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
    return false unless Gitlab::PerformanceBar.enabled_for_user?(current_user)

    if cookies[:perf_bar_enabled].present?
      cookies[:perf_bar_enabled] == 'true'
    else
      cookies[:perf_bar_enabled] = 'true' if Rails.env.development?
    end
  end
end
