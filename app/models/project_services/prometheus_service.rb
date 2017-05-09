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

  def metrics(environment, timeframe_start: nil, timeframe_end: nil)
    with_reactive_cache(environment.slug, timeframe_start, timeframe_end) do |data|
      data
    end
  end

  # Cache metrics for specific environment
  def calculate_reactive_cache(environment_slug, timeframe_start, timeframe_end)
    return unless active? && project && !project.pending_delete?

    timeframe_start = Time.parse(timeframe_start) if timeframe_start
    timeframe_end = Time.parse(timeframe_end) if timeframe_end

    timeframe_start ||= 8.hours.ago
    timeframe_end ||= Time.now

    memory_query = %{(sum(container_memory_usage_bytes{container_name!="POD",environment="#{environment_slug}"}) / count(container_memory_usage_bytes{container_name!="POD",environment="#{environment_slug}"})) /1024/1024}
    cpu_query = %{sum(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="#{environment_slug}"}[2m])) / count(container_cpu_usage_seconds_total{container_name!="POD",environment="#{environment_slug}"}) * 100}

    {
      success: true,
      metrics: {
        # Average Memory used in MB
        memory_values: client.query_range(memory_query, start: timeframe_start, stop: timeframe_end),
        memory_current: client.query(memory_query, time: timeframe_end),
        memory_previous: client.query(memory_query, time: timeframe_start),
        # Average CPU Utilization
        cpu_values: client.query_range(cpu_query, start: timeframe_start, stop: timeframe_end),
        cpu_current: client.query(cpu_query, time: timeframe_end),
        cpu_previous: client.query(cpu_query, time: timeframe_start)
      },
      last_update: Time.now.utc
    }

  rescue Gitlab::PrometheusError => err
    { success: false, result: err.message }
  end

  def client
    @prometheus ||= Gitlab::Prometheus.new(api_url: api_url)
  end
end
