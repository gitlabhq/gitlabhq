class PrometheusService < MonitoringService
  include PrometheusAdapter

  #  Access to prometheus is directly through the API
  prop_accessor :api_url
  boolean_accessor :manual_configuration

  with_options presence: true, if: :manual_configuration? do
    validates :api_url, url: true
  end

  before_save :synchronize_service_state

  after_save :clear_reactive_cache!

  def initialize_properties
    if properties.nil?
      self.properties = {}
    end
  end

  def show_active_box?
    false
  end

  def editable?
    manual_configuration? || !prometheus_installed?
  end

  def title
    'Prometheus'
  end

  def description
    s_('PrometheusService|Time-series monitoring service')
  end

  def self.to_param
    'prometheus'
  end

  def fields
    return [] unless editable?

    [
      {
        type: 'checkbox',
        name: 'manual_configuration',
        title: s_('PrometheusService|Active'),
        required: true
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
    Gitlab::PrometheusClient.new(prometheus_client).ping

    { success: true, result: 'Checked API endpoint' }
  rescue Gitlab::PrometheusClient::Error => err
    { success: false, result: err }
  end

  def prometheus_client
    RestClient::Resource.new(api_url) if api_url && manual_configuration? && active?
  end

  def prometheus_installed?
    return false if template?
    return false unless project

    project.clusters.enabled.any? { |cluster| cluster.application_prometheus&.installed? }
  end

  private

  def synchronize_service_state
    self.active = prometheus_installed? || manual_configuration?

    true
  end
end
