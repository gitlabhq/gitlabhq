class PrometheusService < MonitoringService
  include ReactiveService

  self.reactive_cache_lease_timeout = 30.seconds
  self.reactive_cache_refresh_interval = 30.seconds
  self.reactive_cache_lifetime = 1.minute

  #  Access to prometheus is directly through the API
  prop_accessor :api_url

  with_options presence: true, if: :activated? do
    validates :api_url, url: true
  end

  after_save :clear_reactive_cache!

  def initialize_properties
    if properties.nil?
      self.properties = {}
    end
  end

  def title
    'Prometheus'
  end

  def description
    s_('PrometheusService|Prometheus monitoring')
  end

  def self.to_param
    'prometheus'
  end

  def fields
    [
      {
        type: 'text',
        name: 'api_url',
        title: 'API URL',
        placeholder: s_('PrometheusService|Prometheus API Base URL, like http://prometheus.example.com/'),
        help: s_('PrometheusService|By default, Prometheus listens on ‘http://localhost:9090’. It’s not recommended to change the default address and port as this might affect or conflict with other services running on the GitLab server.'),
        required: true
      }
    ]
  end

  # Check we can connect to the Prometheus API
  def test(*args)
    client.ping

    { success: true, result: 'Checked API endpoint' }
  rescue Gitlab::PrometheusError => err
    { success: false, result: err }
  end

  def environment_metrics(environment)
    with_reactive_cache(Gitlab::Prometheus::Queries::EnvironmentQuery.name, environment.id, &method(:rename_data_to_metrics))
  end

  def deployment_metrics(deployment)
    metrics = with_reactive_cache(Gitlab::Prometheus::Queries::DeploymentQuery.name, deployment.id, &method(:rename_data_to_metrics))
    metrics&.merge(deployment_time: deployment.created_at.to_i) || {}
  end

  def additional_environment_metrics(environment)
    with_reactive_cache(Gitlab::Prometheus::Queries::AdditionalMetricsEnvironmentQuery.name, environment.id, &:itself)
  end

  def additional_deployment_metrics(deployment)
    with_reactive_cache(Gitlab::Prometheus::Queries::AdditionalMetricsDeploymentQuery.name, deployment.id, &:itself)
  end

  def matched_metrics
    with_reactive_cache(Gitlab::Prometheus::Queries::MatchedMetricsQuery.name, &:itself)
  end

  # Cache metrics for specific environment
  def calculate_reactive_cache(query_class_name, *args)
    return unless active? && project && !project.pending_delete?

    data = Kernel.const_get(query_class_name).new(client).query(*args)
    {
      success: true,
      data: data,
      last_update: Time.now.utc
    }
  rescue Gitlab::PrometheusError => err
    { success: false, result: err.message }
  end

  def client
    @prometheus ||= Gitlab::PrometheusClient.new(api_url: api_url)
  end

  private

  def rename_data_to_metrics(metrics)
    metrics[:metrics] = metrics.delete :data
    metrics
  end
end
