class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster
  before_action :authorize_google_api, except: [:login]
  # before_action :authorize_admin_clusters! # TODO: Authentication

  def login
    begin
      @authorize_url = api_client.authorize_url
    rescue GoogleApi::Authentication::ConfigMissingError
    end
  end

  def index
    if cluster
      redirect_to action: 'edit'
    else
      redirect_to action: 'new'
    end
  end

  def new
  end

  def create
    # Create a cluster on GKE
    operation = api_client.projects_zones_clusters_create(
      params['gcp_project_id'], params['cluster_zone'], params['cluster_name'],
      cluster_size: params['cluster_size'], machine_type: params['machine_type']
    )

    # wait_operation_done
    if operation&.operation_type == 'CREATE_CLUSTER'
      api_client.wait_operation_done(operation.self_link)
    else
      raise "TODO: ERROR"
    end

    # Get cluster details (end point, etc)
    gke_cluster = api_client.projects_zones_clusters_get(
      params['gcp_project_id'], params['cluster_zone'], params['cluster_name']
    )

    # Get k8s token
    token = ''
    KubernetesService.new.tap do |ks|
      ks.api_url = 'https://' + gke_cluster.endpoint
      ks.ca_pem = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
      ks.username = gke_cluster.master_auth.username
      ks.password = gke_cluster.master_auth.password
      secrets = ks.read_secrets
      secrets.each do |secret|
        name = secret.dig('metadata', 'name')
        if /default-token/ =~ name
          token_base64 = secret.dig('data', 'token')
          token = Base64.decode64(token_base64)
          break
        end
      end
    end

    # Update service
    kubernetes_service.attributes = service_params(
        active: true,
        api_url: 'https://' + gke_cluster.endpoint,
        ca_pem: Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate),
        namespace: params['project_namespace'],
        token: token
      )

    kubernetes_service.save!

    # Save info
    project.clusters.create(
      gcp_project_id: params['gcp_project_id'],
      cluster_zone: params['cluster_zone'],
      cluster_name: params['cluster_name'],
      service: kubernetes_service
    )

    redirect_to action: 'index'
  end

  def edit
    # TODO: If on, do we override parameter?
    # TODO: If off, do we override parameter?
  end

  def update
    cluster.update(schedule_params)
    render :edit
  end

  private

  def cluster
    # Each project has only one cluster, for now. In the future iteraiton, we'll support multiple clusters
    @cluster ||= project.clusters.last
  end

  def api_client
    @api_client ||=
      GoogleApi::CloudPlatform::Client.new(
        session[GoogleApi::CloudPlatform::Client.token_in_session],
        callback_google_api_authorizations_url,
        state: namespace_project_clusters_url.to_s
      )
  end

  def kubernetes_service
    @kubernetes_service ||= project.find_or_initialize_service('kubernetes')
  end

  def service_params(active:, api_url:, ca_pem:, namespace:, token:)
    {
      active: active,
      api_url: api_url,
      ca_pem: ca_pem,
      namespace: namespace,
      token: token
    }
  end

  def authorize_google_api
    unless session[GoogleApi::CloudPlatform::Client.token_in_session]
      redirect_to action: 'login'
    end
  end
end
