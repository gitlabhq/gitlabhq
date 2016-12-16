# Base class for deployment services
#
# These services integrate with a deployment solution like Kubernetes/OpenShift,
# Mesosphere, etc, to provide additional features to environments.
class DeploymentService < Service
  default_value_for :category, 'deployment'

  def supported_events
    []
  end

  def predefined_variables
    []
  end
end
