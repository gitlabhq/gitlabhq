class Projects::Clusters::GcpController < Projects::ApplicationController
  include ClustersHelper
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]
  helper_method :gcp_authorize_url
  helper_method :token_in_session
  helper_method :valid_gcp_token

  def create
    if valid_gcp_token
      @cluster = ::Clusters::CreateService
        .new(project, current_user, create_params)
        .execute(token_in_session)

      if @cluster.persisted?
        redirect_to project_cluster_path(project, @cluster)
      else
        @gcp_cluster = @cluster
        user_cluster

        render 'projects/clusters/new', locals: { active_tab: 'gcp' }
      end
    else
      redirect_to new_project_cluster_path(@project)
    end
  end

  private

  def create_params
    params.require(:cluster).permit(
      :enabled,
      :name,
      :environment_scope,
      provider_gcp_attributes: [
        :gcp_project_id,
        :zone,
        :num_nodes,
        :machine_type
      ]).merge(
        provider_type: :gcp,
        platform_type: :kubernetes
      )
  end
end
