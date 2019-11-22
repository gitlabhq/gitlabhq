# frozen_string_literal: true

class PrometheusService < MonitoringService
  include PrometheusAdapter

  #  Access to prometheus is directly through the API
  prop_accessor :api_url
  boolean_accessor :manual_configuration

  # We need to allow the self-monitoring project to connect to the internal
  # Prometheus instance.
  # Since the internal Prometheus instance is usually a localhost URL, we need
  # to allow localhost URLs when the following conditions are true:
  # 1. project is the self-monitoring project.
  # 2. api_url is the internal Prometheus URL.
  with_options presence: true, if: :manual_configuration? do
    validates :api_url, public_url: true, unless: proc { |object| object.allow_local_api_url? }
    validates :api_url, url: true, if: proc { |object| object.allow_local_api_url? }
  end

  before_save :synchronize_service_state

  after_save :clear_reactive_cache!

  after_commit :track_events

  def initialize_properties
    if properties.nil?
      self.properties = {}
    end
  end

  def show_active_box?
    false
  end

  def editable?
    manual_configuration? || !prometheus_available?
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
        required: true
      }
    ]
  end

  # Check we can connect to the Prometheus API
  def test(*args)
    prometheus_client.ping
    { success: true, result: 'Checked API endpoint' }
  rescue Gitlab::PrometheusClient::Error => err
    { success: false, result: err }
  end

  def prometheus_client
    return unless should_return_client?

    Gitlab::PrometheusClient.new(api_url)
  end

  def prometheus_available?
    return false if template?
    return false unless project

    project.clusters.enabled.any? { |cluster| cluster.application_prometheus_available? }
  end

  def allow_local_api_url?
    self_monitoring_project? && internal_prometheus_url?
  end

  private

  def self_monitoring_project?
    project && project.id == current_settings.instance_administration_project_id
  end

  def internal_prometheus_url?
    api_url.present? && api_url == ::Gitlab::Prometheus::Internal.uri
  end

  def should_return_client?
    api_url.present? && manual_configuration? && active? && valid?
  end

  def current_settings
    Gitlab::CurrentSettings.current_application_settings
  end

  def synchronize_service_state
    self.active = prometheus_available? || manual_configuration?

    true
  end

  def track_events
    if enabled_manual_prometheus?
      Gitlab::Tracking.event('cluster:services:prometheus', 'enabled_manual_prometheus')
    elsif disabled_manual_prometheus?
      Gitlab::Tracking.event('cluster:services:prometheus', 'disabled_manual_prometheus')
    end

    true
  end

  def enabled_manual_prometheus?
    manual_configuration_changed? && manual_configuration?
  end

  def disabled_manual_prometheus?
    manual_configuration_changed? && !manual_configuration?
  end
end
