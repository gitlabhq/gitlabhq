class Projects::Clusters::UserController < Projects::ApplicationController
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:new, :create]

  def new
    @cluster = ::Clusters::Cluster.new.tap do |cluster|
      cluster.build_platform_kubernetes
    end
  end

  def create
    @cluster = ::Clusters::CreateService
      .new(project, current_user, create_params)
      .execute

    if @cluster.persisted?
      redirect_to project_cluster_path(project, @cluster)
    else
      render :new
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
