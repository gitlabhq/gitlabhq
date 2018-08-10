# frozen_string_literal: true

class MockMonitoringService < MonitoringService
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
    JSON.parse(File.read(Rails.root + 'spec/fixtures/metrics.json'))
  end

  def can_test?
    false
  end
end
