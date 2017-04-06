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
    JSON.parse(Rails.root.join('spec', 'fixtures', 'metrics.json'))
  end
end
