# frozen_string_literal: true

class Clusters::ClustersController < ::Clusters::BaseController
  include RoutableActions

  before_action :cluster, only: [:cluster_status, :show, :update, :destroy, :clear_cache]
  before_action :user_cluster, only: [:connect]
  before_action :authorize_read_cluster!, only: [:show, :index]
  before_action :authorize_create_cluster!, only: [:connect]
  before_action :authorize_update_cluster!, only: [:update]
  before_action :ensure_feature_enabled!, except: [:index, :new_cluster_docs]

  helper_method :token_in_session

  STATUS_POLLING_INTERVAL = 10_000

  def index
    @clusters = cluster_list

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: STATUS_POLLING_INTERVAL)
        serializer = ClusterSerializer.new(current_user: current_user)

        render json: {
          clusters: serializer.with_pagination(request, response).represent_list(@clusters),
          has_ancestor_clusters: @has_ancestor_clusters
        }
      end
    end
  end

  # Overriding ActionController::Metal#status is NOT a good idea
  def cluster_status
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: STATUS_POLLING_INTERVAL)

        render json: ClusterSerializer
          .new(current_user: @current_user)
          .represent_status(@cluster)
      end
    end
  end

  def show
    if safe_params[:tab] == 'integrations'
      @prometheus_integration = Clusters::IntegrationPresenter.new(@cluster.find_or_build_integration_prometheus)
    end
  end

  def update
    Clusters::UpdateService
      .new(current_user, update_params)
      .execute(cluster)

    if cluster.valid?
      respond_to do |format|
        format.json do
          head :no_content
        end
        format.html do
          flash[:notice] = _('Kubernetes cluster was successfully updated.')
          redirect_to cluster.show_path
        end
      end
    else
      respond_to do |format|
        format.json { head :bad_request }
        format.html { render :show }
      end
    end
  end

  def destroy
    response = Clusters::DestroyService
      .new(current_user, destroy_params)
      .execute(cluster)

    flash[:notice] = response[:message]
    redirect_to clusterable.index_path, status: :found
  end

  def create_user
    @user_cluster = ::Clusters::CreateService
      .new(current_user, create_user_cluster_params)
      .execute(access_token: token_in_session)
      .present(current_user: current_user)

    if @user_cluster.persisted?
      redirect_to @user_cluster.show_path
    else
      render :connect
    end
  end

  def clear_cache
    cluster.delete_cached_resources!

    redirect_to cluster.show_path, notice: _('Cluster cache cleared.')
  end

  private

  def ensure_feature_enabled!
    render_404 unless clusterable.certificate_based_clusters_enabled?
  end

  def cluster_list
    return [] unless clusterable.certificate_based_clusters_enabled?

    finder = ClusterAncestorsFinder.new(clusterable.__subject__, current_user)
    clusters = finder.execute

    @has_ancestor_clusters = finder.has_ancestor_clusters?

    # Note: We are paginating through an array here but this should OK as:
    #
    # In CE, we can have a maximum group nesting depth of 21, so including
    # project cluster, we can have max 22 clusters for a group hierarchy.
    # In EE (Premium) we can have any number, as multiple clusters are
    # supported, but the number of clusters are fairly low currently.
    #
    # See https://gitlab.com/gitlab-org/gitlab-foss/issues/55260 also.
    Kaminari.paginate_array(clusters).page(safe_params[:page]).per(20)
  end

  def destroy_params
    params.permit(:cleanup)
  end

  def base_permitted_cluster_params
    [
      :enabled,
      :environment_scope,
      :managed,
      :namespace_per_environment
    ]
  end

  def update_params
    if cluster.provided_by_user?
      params.require(:cluster).permit(
        *base_permitted_cluster_params,
        :name,
        :base_domain,
        :management_project_id,
        platform_kubernetes_attributes: [
          :api_url,
          :token,
          :ca_cert,
          :namespace
        ]
      )
    else
      params.require(:cluster).permit(
        *base_permitted_cluster_params,
        :base_domain,
        :management_project_id,
        platform_kubernetes_attributes: [
          :namespace
        ]
      )
    end
  end

  def create_user_cluster_params
    params.require(:cluster).permit(
      *base_permitted_cluster_params,
      :name,
      platform_kubernetes_attributes: [
        :namespace,
        :api_url,
        :token,
        :ca_cert,
        :authorization_type
      ]).merge(
        provider_type: :user,
        platform_type: :kubernetes,
        clusterable: clusterable.__subject__
      )
  end

  def user_cluster
    cluster = Clusters::BuildService.new(clusterable.__subject__).execute
    cluster.build_platform_kubernetes
    @user_cluster = cluster.present(current_user: current_user)
  end

  def token_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def expires_at_in_session
    @expires_at_in_session ||=
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end

  def safe_params
    params.permit(:tab, :page)
  end
end

Clusters::ClustersController.prepend_mod_with('Clusters::ClustersController')
