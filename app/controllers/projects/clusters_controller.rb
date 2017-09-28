class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:login, :index, :new, :create]
  before_action :authorize_google_api, except: [:login]
  # before_action :authorize_admin_clusters! # TODO: Authentication

  def login
    begin
      @authorize_url = api_client.authorize_url
    rescue GoogleApi::Authentication::ConfigMissingError
      # Show an alert message that gitlab.yml is not configured properly
    end
  end

  def index
    if project.clusters.any?
      redirect_to edit_project_cluster_path(project, project.clusters.last.id)
    else
      redirect_to new_project_cluster_path(project)
    end
  end

  def new
  end

  def create
    begin
      Ci::CreateClusterService.new(project, current_user, params)
                              .create_cluster_on_gke(api_client)
    rescue Ci::CreateClusterService::UnexpectedOperationError => e
      # TODO: error
      puts "#{self.class.name} - #{__callee__}: e: #{e}"
    end

    redirect_to project_clusters_path(project)
  end

  ##
  # Return
  # @status: The current status of the operation.
  # @status_message: If an error has occurred, a textual description of the error.
  def creation_status
    respond_to do |format|
      format.json do
        render json: cluster.creation_status(session[GoogleApi::CloudPlatform::Client.token_in_session])
      end
    end
  end

  def edit
  end

  def update
    Ci::Cluster.transaction do
      if params['enabled'] == 'true'

        cluster.service.attributes = {
          active: true,
          api_url: cluster.endpoint,
          ca_pem: cluster.ca_cert,
          namespace: cluster.project_namespace,
          token: cluster.token
        }

        cluster.service.save!
      else
        cluster.service.update(active: false)
      end

      cluster.update(enabled: params['enabled'])
    end

    render :edit
  end

  def destroy
    if cluster.destroy
      redirect_to project_clusters_path(project), status: 302
    else
      redirect_to project_clusters_path(project),
                  status: :forbidden,
                  alert: _("Failed to remove the cluster")
    end
  end

  private

  def cluster
    @cluster ||= project.clusters.find(params[:id])
  end

  def api_client
    @api_client ||=
      GoogleApi::CloudPlatform::Client.new(
        session[GoogleApi::CloudPlatform::Client.token_in_session],
        callback_google_api_authorizations_url,
        state: namespace_project_clusters_url.to_s
      )
  end

  def authorize_google_api
    unless session[GoogleApi::CloudPlatform::Client.token_in_session]
      redirect_to action: 'login'
    end
  end
end
