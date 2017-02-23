class PrometheusService < MonitoringService
  include Gitlab::Prometheus
  include ReactiveCaching

  self.reactive_cache_key = ->(service) { [ service.class.model_name.singular, service.project_id ] }
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
  end

  def self.to_param
    'prometheus'
  end

  def fields
    [
        { type: 'text',
          name: 'api_url',
          title: 'API URL',
          placeholder: 'Prometheus API URL, like http://prometheus.example.com/',
        }
    ]
  end

  # Check we can connect to the Prometheus API
  def test(*args)
    self.ping

    { success: true, result: "Checked API endpoint" }
  rescue ::Gitlab::PrometheusError => err
    { success: false, result: err }
  end

  def metrics(environment)
    with_reactive_cache(environment.slug) do |data|
      data
    end
  end

  # Cache metrics for specific environment
  def calculate_reactive_cache(environment)
    return unless active? && project && !project.pending_delete?

    # TODO: encode environment
    {
      success: true,
      metrics: {
        #Memory used in MB
        memory_values: query_range("sum(container_memory_usage_bytes{container_name=\"app\", environment=\"#{environment}\"})/1024/1024", 8.hours.ago),
        memory_current: query("sum(container_memory_usage_bytes{container_name=\"app\", environment=\"#{environment}\"})/1024/1024"),
        #CPU Usage in Seconds.
        cpu_values: query_range("sum(rate(container_cpu_usage_seconds_total{container_name=\"app\",environment=\"#{environment}\"}[2m]))", 8.hours.ago),
        cpu_current: query("sum(rate(container_cpu_usage_seconds_total{container_name=\"app\",environment=\"#{environment}\"}[2m]))"),
      },
      last_update: Time.now.utc,
    }

  rescue ::Gitlab::PrometheusError => err
    { success: false, result: err }
  end
end
