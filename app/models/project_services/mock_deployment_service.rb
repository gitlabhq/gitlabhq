# frozen_string_literal: true

class MockDeploymentService < Service
  default_value_for :category, 'deployment'

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

  def self.supported_events
    %w()
  end

  def predefined_variables(project:, environment_name:)
    []
  end

  def can_test?
    false
  end

  def rollout_status(environment)
    case environment.name
    when 'staging'
      ::Gitlab::Kubernetes::RolloutStatus.new([], status: :not_found)
    when 'test'
      ::Gitlab::Kubernetes::RolloutStatus.new([], status: :loading)
    else
      ::Gitlab::Kubernetes::RolloutStatus.new(rollout_status_deployments)
    end
  end

  private

  def rollout_status_instances
    data = File.read(Rails.root.join('spec', 'fixtures', 'rollout_status_instances.json'))
    Gitlab::Json.parse(data)
  end

  def rollout_status_deployments
    [OpenStruct.new(instances: rollout_status_instances)]
  end
end
