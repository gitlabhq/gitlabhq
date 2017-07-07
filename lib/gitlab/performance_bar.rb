module Gitlab
  module PerformanceBar
    def self.enabled?
      Rails.env.development? || Feature.enabled?('gitlab_performance_bar')
    end
  end
end
