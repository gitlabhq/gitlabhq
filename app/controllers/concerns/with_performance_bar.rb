module WithPerformanceBar
  extend ActiveSupport::Concern

  included do
    include Peek::Rblineprof::CustomControllerHelpers
  end

  def peek_enabled?
    return false unless Gitlab::PerformanceBar.enabled?(current_user)

    cookie = cookies[:perf_bar_enabled]
    cookie ||= (cookies[:perf_bar_enabled] = 'true') if Rails.env.development?

    cookie === 'true'
  end
end
