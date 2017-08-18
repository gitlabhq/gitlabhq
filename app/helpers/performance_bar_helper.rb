module PerformanceBarHelper
  # This is a hack since using `alias_method :performance_bar_enabled?, :peek_enabled?`
  # in WithPerformanceBar breaks tests (but works in the browser).
  def performance_bar_enabled?
    peek_enabled?
  end
end
