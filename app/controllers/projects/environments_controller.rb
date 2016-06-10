class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'
  before_action :authorize_read_environment!
  before_action :environment, only: [:show]

  def index
    @environments = project.environments
  end

  def show
  end

  private

  def environment
    @environment ||= project.environments.find(params[:id].to_s)
    @environment || render_404
  end
end
