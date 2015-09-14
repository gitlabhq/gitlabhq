module Ci
  class WebHooksController < Ci::ApplicationController
    before_action :authenticate_user!
    before_action :project
    before_action :authorize_access_project!
    before_action :authorize_manage_project!

    layout 'ci/project'

    def index
      @web_hooks = @project.web_hooks
      @web_hook = Ci::WebHook.new
    end

    def create
      @web_hook = @project.web_hooks.new(web_hook_params)
      @web_hook.save

      if @web_hook.valid?
        redirect_to ci_project_web_hooks_path(@project)
      else
        @web_hooks = @project.web_hooks.select(&:persisted?)
        render :index
      end
    end

    def test
      Ci::TestHookService.new.execute(hook, current_user)

      redirect_to :back
    end

    def destroy
      hook.destroy

      redirect_to ci_project_web_hooks_path(@project)
    end

    private

    def hook
      @web_hook ||= @project.web_hooks.find(params[:id])
    end

    def project
      @project = Ci::Project.find(params[:project_id])
    end

    def web_hook_params
      params.require(:web_hook).permit(:url)
    end
  end
end
