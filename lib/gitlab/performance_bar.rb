module Gitlab
  module PerformanceBar
    def self.enabled?
      ENV["PERFORMANCE_BAR"] == '1'
    end
  end
end
