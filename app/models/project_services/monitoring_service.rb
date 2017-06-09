# Base class for monitoring services
#
# These services integrate with a deployment solution like Prometheus
# to provide additional features for environments.
class MonitoringService < Service
  default_value_for :category, 'monitoring'

  def self.supported_events
    %w()
  end

<<<<<<< HEAD
  # Environments have a number of metrics
  def metrics(environment, timeframe_start: nil, timeframe_end: nil)
=======
  def environment_metrics(environment)
    raise NotImplementedError
  end

  def deployment_metrics(deployment)
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
    raise NotImplementedError
  end
end
