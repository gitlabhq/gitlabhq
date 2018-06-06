class Projects::Clusters::UserController < Projects::ApplicationController
  include ClustersHelper
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]
  helper_method :gcp_authorize_url
  helper_method :token_in_session
  helper_method :valid_gcp_token

  def create
    @cluster = ::Clusters::CreateService
      .new(project, current_user, create_params)
      .execute

    if @cluster.persisted?
      redirect_to project_cluster_path(project, @cluster)
    else
      @user_cluster = @cluster
      gcp_cluster

      render 'projects/clusters/new', locals: { active_tab: 'user' }
    end
  end

  private

  def create_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :environment_scope,
      platform_kubernetes_attributes: [
        :namespace,
        :api_url,
        :token,
        :ca_cert
      ]).merge(
        provider_type: :user,
        platform_type: :kubernetes
      )
  end
end

