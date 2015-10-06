class Projects::BuildsController < Projects::ApplicationController
  before_action :ci_project
  before_action :build

  layout "project"

  def show
    @builds = @ci_project.commits.find_by_sha(@build.sha).builds.order('id DESC')
    @builds = @builds.where("id not in (?)", @build.id).page(params[:page]).per(20)
    @commit = @build.commit

    respond_to do |format|
      format.html
      format.json do
        render json: @build.to_json(methods: :trace_html)
      end
    end
  end

  private

  def build
    @build ||= ci_project.builds.unscoped.find_by(id: params[:id])
  end
end
