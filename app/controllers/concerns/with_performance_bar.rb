module WithPerformanceBar
  extend ActiveSupport::Concern

  included do
    include Peek::Rblineprof::CustomControllerHelpers
  end

  def peek_enabled?
    return false unless Gitlab::PerformanceBar.enabled?(current_user)

    cookie = cookies[:perf_bar_enabled]

    if !cookie.present?
      if Rails.env.development?
        cookies[:perf_bar_enabled] = 'true'
        return true
      else
        return false
      end
    end

    cookie === 'true'
  end
end
