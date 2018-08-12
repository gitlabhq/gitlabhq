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
    data = File.read(Rails.root.join('spec', 'fixtures', 'metrics.json'))
    JSON.parse(data)
  end

  def can_test?
    false
  end
end
