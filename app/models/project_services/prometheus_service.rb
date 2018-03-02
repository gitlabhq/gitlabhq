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
    client.ping

    { success: true, result: 'Checked API endpoint' }
  rescue Gitlab::PrometheusClient::Error => err
    { success: false, result: err }
  end

  def environment_metrics(environment)
    with_reactive_cache(Gitlab::Prometheus::Queries::EnvironmentQuery.name, environment.id, &rename_field(:data, :metrics))
  end

  def deployment_metrics(deployment)
    metrics = with_reactive_cache(Gitlab::Prometheus::Queries::DeploymentQuery.name, deployment.environment.id, deployment.id, &rename_field(:data, :metrics))
    metrics&.merge(deployment_time: deployment.created_at.to_i) || {}
  end

  def additional_environment_metrics(environment)
    with_reactive_cache(Gitlab::Prometheus::Queries::AdditionalMetricsEnvironmentQuery.name, environment.id, &:itself)
  end

  def additional_deployment_metrics(deployment)
    with_reactive_cache(Gitlab::Prometheus::Queries::AdditionalMetricsDeploymentQuery.name, deployment.environment.id, deployment.id, &:itself)
  end

  def matched_metrics
    with_reactive_cache(Gitlab::Prometheus::Queries::MatchedMetricsQuery.name, &:itself)
  end

  # Cache metrics for specific environment
  def calculate_reactive_cache(query_class_name, *args)
    return unless active? && project && !project.pending_delete?

    environment_id = args.first
    client = client(environment_id)

    data = Kernel.const_get(query_class_name).new(client).query(*args)
    {
      success: true,
      data: data,
      last_update: Time.now.utc
    }
  rescue Gitlab::PrometheusClient::Error => err
    { success: false, result: err.message }
  end

  def client(environment_id = nil)
    if manual_configuration?
      Gitlab::PrometheusClient.new(RestClient::Resource.new(api_url))
    else
      cluster = cluster_with_prometheus(environment_id)
      raise Gitlab::PrometheusClient::Error, "couldn't find cluster with Prometheus installed" unless cluster

      rest_client = client_from_cluster(cluster)
      raise Gitlab::PrometheusClient::Error, "couldn't create proxy Prometheus client" unless rest_client

      Gitlab::PrometheusClient.new(rest_client)
    end
  end

  def prometheus_installed?
    return false if template?
    return false unless project

    project.clusters.enabled.any? { |cluster| cluster.application_prometheus&.installed? }
  end

  private

  def cluster_with_prometheus(environment_id = nil)
    clusters = if environment_id
                 ::Environment.find_by(id: environment_id).try do |env|
                   # sort results by descending order based on environment_scope being longer
                   # thus more closely matching environment slug
                   project.clusters.enabled.for_environment(env).sort_by { |c| c.environment_scope&.length }.reverse!
                 end
               else
                 project.clusters.enabled.for_all_environments
               end

    clusters&.detect { |cluster| cluster.application_prometheus&.installed? }
  end

  def client_from_cluster(cluster)
    cluster.application_prometheus.proxy_client
  end

  def rename_field(old_field, new_field)
    -> (metrics) do
      metrics[new_field] = metrics.delete(old_field)
      metrics
    end
  end

  def synchronize_service_state!
    self.active = prometheus_installed? || manual_configuration?

    true
  end
end
