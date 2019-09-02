# frozen_string_literal: true

module PerformanceBarHelper
  def performance_bar_enabled?
    Gitlab::PerformanceBar.enabled_for_request?
  end
end
