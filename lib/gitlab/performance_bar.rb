module Gitlab
  module PerformanceBar
    def self.enabled?
      Feature.enabled?('gitlab_performance_bar')
    end
  end
end
