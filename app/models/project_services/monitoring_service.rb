# Base class for monitoring services
#
# These services integrate with a deployment solution like Kubernetes/OpenShift,
# Mesosphere, etc, to provide additional features to environments.
class MonitoringService < Service
  default_value_for :category, 'monitoring'

  def self.supported_events
    %w()
  end

  # Environments have a number of metrics
  def metrics(environment, period)
    raise NotImplementedError
  end
end
