# frozen_string_literal: true

# Deprecated, to be deleted in 13.8 (https://gitlab.com/gitlab-org/gitlab/-/issues/293914)
#
# This was a class used only in development environment but became unusable
# since DeploymentService was deleted
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
end
