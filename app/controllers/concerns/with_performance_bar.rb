# frozen_string_literal: true

module WithPerformanceBar
  extend ActiveSupport::Concern

  included do
    before_action :peek_enabled? # Warm cache
  end

  protected

  def peek_enabled?
    return false unless Gitlab::PerformanceBar.enabled?(current_user)

    Gitlab::SafeRequestStore.fetch(:peek_enabled) { cookie_or_default_value }
  end

  private

  def cookie_or_default_value
    if cookies[:perf_bar_enabled].present?
      cookies[:perf_bar_enabled] == 'true'
    else
      cookies[:perf_bar_enabled] = 'true' if Rails.env.development?
    end
  end
end
