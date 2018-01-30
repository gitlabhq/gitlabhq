class PrometheusService < MonitoringService
  include ReactiveService

  self.reactive_cache_lease_timeout = 30.seconds
  self.reactive_cache_refresh_interval = 30.seconds
  self.reactive_cache_lifetime = 1.minute
  #  Access to prometheus is directly through the API
  prop_accessor :api_url
  boolean_accessor :manual_configuration

  with_options presence: true, if: :manual_configuration? do
    validates :api_url, url: true
  end

  before_save :synchronize_service_state!

  after_save :clear_reactive_cache!

  def initialize_properties
    if properties.nil?
      self.properties = {}
    end
  end

  def show_active_box?
    false
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
        type: 'fieldset',
        legend: 'Manual Configuration',
        fields: [
          {
            type: 'checkbox',
            name: 'manual_configuration',
            title: s_('PrometheusService|Active'),
            required: true
          }
        ]
      },
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

  def calculate_reactive_cache(query_class_name, environment_id, *args)
    client = Gitlab::PrometheusClient.new(RestClient::Resource.new(api_url))
    Gitlab::Prometheus::QueryingAdapter.calculate_reactive_cache(client, query_class_name, environment_id, *args)
  end

  def prometheus_installed?
    return false if template?
    project.clusters.enabled.any? { |cluster| cluster.application_prometheus&.installed? }
  end

  private

  def synchronize_service_state!
    self.active = prometheus_installed? || self.manual_configuration?

    true
  end
end
