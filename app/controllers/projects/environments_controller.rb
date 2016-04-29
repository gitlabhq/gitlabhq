class Projects::EnvironmentsController < Projects::ApplicationController
  layout 'project'

  def index
    @environments = project.builds.where.not(environment: nil).pluck(:environment).uniq
    @environments = @environments.map { |env| build_for_env(env) }.compact
  end

  def show
    @environment = params[:id].to_s
    @builds = project.builds.where.not(status: ["manual"]).where(environment: params[:id].to_s).order(id: :desc).page(params[:page]).per(30)
  end

  def build_for_env(environment)
    project.builds.success.order(id: :desc).find_by(environment: environment)
  end
end
