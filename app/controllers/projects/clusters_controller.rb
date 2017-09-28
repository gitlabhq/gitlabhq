class Projects::ClustersController < Projects::ApplicationController
  before_action :cluster, except: [:login, :index, :new, :create]
  before_action :authorize_google_api, except: [:login]
  # before_action :authorize_admin_clusters! # TODO: Authentication

  def login
    begin
      @authorize_url = api_client.authorize_url
    rescue GoogleApi::Authentication::ConfigMissingError
    end
  end

  def index
    if project.clusters.any?
      redirect_to edit_namespace_project_cluster_path(project.namespace, project, project.clusters.last.id)
    else
      redirect_to action: 'new'
    end
  end

  def new
  end

  def create
    begin
      Ci::CreateClusterService.new(project, current_user, params)
                              .create_cluster_on_gke(api_client)
    rescue Ci::CreateClusterService::UnexpectedOperationError => e
      puts "#{self.class.name} - #{__callee__}: e: #{e}"
      # TODO: error
    end

    redirect_to action: 'index'
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
    cluster.update(enabled: params['enabled'])
    cluster.service.update(active: params['enabled'])
    # TODO: Do we overwrite KubernetesService parameter?
    render :edit
  end

  def destroy
    cluster.destroy
    redirect_to action: 'index'
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
