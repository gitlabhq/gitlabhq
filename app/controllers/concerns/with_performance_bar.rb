module WithPerformanceBar
  extend ActiveSupport::Concern

  included do
    include Peek::Rblineprof::CustomControllerHelpers
  end

  def peek_enabled?
    return false unless Gitlab::PerformanceBar.enabled?(current_user)

    if RequestStore.active?
      RequestStore.fetch(:peek_enabled) { cookie_or_default_value }
    else
      cookie_or_default_value
    end
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
