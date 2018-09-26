class Groups::Clusters::ApplicationsController < Groups::ApplicationController
  before_action :cluster
  before_action :application_class, only: [:create]
  before_action :authorize_read_cluster!
  before_action :authorize_create_cluster!, only: [:create]

  # rubocop: disable CodeReuse/ActiveRecord
  def create
    application = @application_class.find_or_initialize_by(cluster: @cluster)

    if application.has_attribute?(:hostname)
      application.hostname = params[:hostname]
    end

    if application.respond_to?(:oauth_application)
      application.oauth_application = create_oauth_application(application)
    end

    application.save!

    Clusters::Applications::ScheduleInstallationService.new(current_user).execute(application)

    head :no_content
  rescue StandardError
    head :bad_request
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def cluster
    @cluster ||= group.clusters.find(params[:id]) || render_404
  end

  def application_class
    @application_class ||= Clusters::Cluster::APPLICATIONS[params[:application]] || render_404
  end

  def create_oauth_application(application)
    oauth_application_params = {
      name: params[:application],
      redirect_uri: application.callback_url,
      scopes: 'api read_user openid',
      owner: current_user
    }

    Applications::CreateService.new(current_user, oauth_application_params).execute(request)
  end

  def authorize_read_cluster!
    unless can?(current_user, :read_cluster, group)
      access_denied!
    end
  end

  def authorize_create_cluster!
    unless can?(current_user, :create_cluster, group)
      access_denied!
    end
  end
end
