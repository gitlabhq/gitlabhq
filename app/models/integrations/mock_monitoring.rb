# frozen_string_literal: true

module Integrations
  class MockMonitoring < BaseMonitoring
    def title
      'Mock monitoring'
    end

    def description
      'Mock monitoring service'
    end

    def self.to_param
      'mock_monitoring'
    end

    def metrics(environment)
      Gitlab::Json.parse(File.read(Rails.root + 'spec/fixtures/metrics.json'))
    end

    def testable?
      false
    end
  end
end
