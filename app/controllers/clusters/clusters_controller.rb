# frozen_string_literal: true

class Clusters::ClustersController < Clusters::BaseController
  include RoutableActions
  include Metrics::Dashboard::PrometheusApiProxy
  include MetricsDashboard

  before_action :cluster, only: [:cluster_status, :show, :update, :destroy, :clear_cache]
  before_action :generate_gcp_authorize_url, only: [:new]
  before_action :validate_gcp_token, only: [:new]
  before_action :gcp_cluster, only: [:new]
  before_action :user_cluster, only: [:new]
  before_action :authorize_create_cluster!, only: [:new, :authorize_aws_role]
  before_action :authorize_update_cluster!, only: [:update]
  before_action :authorize_admin_cluster!, only: [:destroy, :clear_cache]
  before_action :update_applications_status, only: [:cluster_status]

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

  def new
    if params[:provider] == 'aws'
      @aws_role = Aws::Role.create_or_find_by!(user: current_user)
      @instance_types = load_instance_types.to_json

    elsif params[:provider] == 'gcp'
      redirect_to @authorize_url if @authorize_url && !@valid_gcp_token
    end
  end

  # Overridding ActionController::Metal#status is NOT a good idea
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
    if params[:tab] == 'integrations'
      @prometheus_integration = Clusters::IntegrationPresenter.new(@cluster.find_or_build_integration_prometheus)
      @elastic_stack_integration = Clusters::IntegrationPresenter.new(@cluster.find_or_build_integration_elastic_stack)
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

  def create_gcp
    @gcp_cluster = ::Clusters::CreateService
      .new(current_user, create_gcp_cluster_params)
      .execute(access_token: token_in_session)
      .present(current_user: current_user)

    if @gcp_cluster.persisted?
      redirect_to @gcp_cluster.show_path
    else
      generate_gcp_authorize_url
      validate_gcp_token
      user_cluster
      params[:provider] = 'gcp'

      render :new, locals: { active_tab: 'create' }
    end
  end

  def create_aws
    @aws_cluster = ::Clusters::CreateService
      .new(current_user, create_aws_cluster_params)
      .execute
      .present(current_user: current_user)

    if @aws_cluster.persisted?
      head :created, location: @aws_cluster.show_path
    else
      render status: :unprocessable_entity, json: @aws_cluster.errors
    end
  end

  def create_user
    @user_cluster = ::Clusters::CreateService
      .new(current_user, create_user_cluster_params)
      .execute(access_token: token_in_session)
      .present(current_user: current_user)

    if @user_cluster.persisted?
      redirect_to @user_cluster.show_path
    else
      generate_gcp_authorize_url
      validate_gcp_token
      gcp_cluster

      render :new, locals: { active_tab: 'add' }
    end
  end

  def authorize_aws_role
    response = Clusters::Aws::AuthorizeRoleService.new(
      current_user,
      params: aws_role_params
    ).execute

    render json: response.body, status: response.status
  end

  def clear_cache
    cluster.delete_cached_resources!

    redirect_to cluster.show_path, notice: _('Cluster cache cleared.')
  end

  private

  def cluster_list
    finder = ClusterAncestorsFinder.new(clusterable.subject, current_user)
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
    Kaminari.paginate_array(clusters).page(params[:page]).per(20)
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

  def create_gcp_cluster_params
    params.require(:cluster).permit(
      *base_permitted_cluster_params,
      :name,
      provider_gcp_attributes: [
        :gcp_project_id,
        :zone,
        :num_nodes,
        :machine_type,
        :cloud_run,
        :legacy_abac
      ]).merge(
        provider_type: :gcp,
        platform_type: :kubernetes,
        clusterable: clusterable.subject
      )
  end

  def create_aws_cluster_params
    params.require(:cluster).permit(
      *base_permitted_cluster_params,
      :name,
      provider_aws_attributes: [
        :kubernetes_version,
        :key_name,
        :role_arn,
        :region,
        :vpc_id,
        :instance_type,
        :num_nodes,
        :security_group_id,
        subnet_ids: []
      ]).merge(
        provider_type: :aws,
        platform_type: :kubernetes,
        clusterable: clusterable.subject
      )
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
        clusterable: clusterable.subject
      )
  end

  def aws_role_params
    params.require(:cluster).permit(:role_arn, :region)
  end

  def generate_gcp_authorize_url
    state = generate_session_key_redirect(clusterable.new_path(provider: :gcp).to_s)

    @authorize_url = GoogleApi::CloudPlatform::Client.new(
      nil, callback_google_api_auth_url,
      state: state).authorize_url
  rescue GoogleApi::Auth::ConfigMissingError
    # no-op
  end

  def gcp_cluster
    cluster = Clusters::BuildService.new(clusterable.subject).execute
    cluster.build_provider_gcp
    @gcp_cluster = cluster.present(current_user: current_user)
  end

  def proxyable
    cluster.cluster
  end

  # During first iteration of dashboard variables implementation
  # cluster health case was omitted. Existing service for now is tied to
  # environment, which is not always present for cluster health dashboard.
  # It is planned to break coupling to environment https://gitlab.com/gitlab-org/gitlab/-/issues/213833.
  # It is also planned to move cluster health to metrics dashboard section https://gitlab.com/gitlab-org/gitlab/-/issues/220214
  # but for now I've used dummy class to stub variable substitution service, as there are no variables
  # in cluster health dashboard
  def proxy_variable_substitution_service
    @empty_service ||= Class.new(BaseService) do
      def initialize(proxyable, params)
        @proxyable = proxyable
        @params = params
      end

      def execute
        success(params: @params)
      end
    end
  end

  def user_cluster
    cluster = Clusters::BuildService.new(clusterable.subject).execute
    cluster.build_platform_kubernetes
    @user_cluster = cluster.present(current_user: current_user)
  end

  def validate_gcp_token
    @valid_gcp_token = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
      .validate_token(expires_at_in_session)
  end

  def token_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def expires_at_in_session
    @expires_at_in_session ||=
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end

  def generate_session_key_redirect(uri)
    GoogleApi::CloudPlatform::Client.new_session_key_for_redirect_uri do |key|
      session[key] = uri
    end
  end

  ##
  # Unfortunately the EC2 API doesn't provide a list of
  # possible instance types. There is a workaround, using
  # the Pricing API, but instead of requiring the
  # user to grant extra permissions for this we use the
  # values that validate the CloudFormation template.
  def load_instance_types
    stack_template = File.read(Rails.root.join('vendor', 'aws', 'cloudformation', 'eks_cluster.yaml'))
    instance_types = YAML.safe_load(stack_template).dig('Parameters', 'NodeInstanceType', 'AllowedValues')

    instance_types.map { |type| Hash(name: type, value: type) }
  end

  def update_applications_status
    @cluster.applications.each(&:schedule_status_update)
  end
end

Clusters::ClustersController.prepend_mod_with('Clusters::ClustersController')
