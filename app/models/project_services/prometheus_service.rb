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
    'Prometheus monitoring'
  end

  def help
    <<-MD.strip_heredoc
      Retrieves the Kubernetes node metrics `container_cpu_usage_seconds_total`
      and `container_memory_usage_bytes` from the configured Prometheus server.

      If you are not using [Auto-Deploy](https://docs.gitlab.com/ee/ci/autodeploy/index.html)
      or have set up your own Prometheus server, an `environment` label is required on each metric to
      [identify the Environment](https://docs.gitlab.com/ce/user/project/integrations/prometheus.html#metrics-and-labels).
    MD
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
        placeholder: 'Prometheus API Base URL, like http://prometheus.example.com/'
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

  def environment_metrics(environment, **args)
    with_reactive_cache(Gitlab::Prometheus::Queries::EnvironmentQuery.name, environment.id, &:itself)
  end

  def deployment_metrics(deployment)
    with_reactive_cache(Gitlab::Prometheus::Queries::DeploymentQuery.name, deployment.id, &:itself)
  end

  # Cache metrics for specific environment
  def calculate_reactive_cache(query_class_name, *args)
    return unless active? && project && !project.pending_delete?

    metrics = Kernel.const_get(query_class_name).new(client).query(*args)

    {
      success: true,
      metrics: metrics,
      last_update: Time.now.utc
    }
  rescue Gitlab::PrometheusError => err
    { success: false, result: err.message }
  end

  def client
    @prometheus ||= Gitlab::PrometheusClient.new(api_url: api_url)
  end
end
