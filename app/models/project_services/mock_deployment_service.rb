class MockDeploymentService < DeploymentService
  def title
    'Mock deployment'
  end

  def description
    'Mock deployment service'
  end

  def self.to_param
    'mock_deployment'
  end

  # No terminals support
  def terminals(environment)
    []
  end

  def rollout_status(environment)
    OpenStruct.new(
      instances: rollout_status_instances,
      completion: 80,
      valid?: true,
      complete?: true
    )
  end

  private

  def rollout_status_instances
    data = File.read(Rails.root.join('spec', 'fixtures', 'rollout_status_instances.json'))
    JSON.parse(data)
  end
end
