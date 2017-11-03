class Groups::PipelineQuotaController < Groups::ApplicationController
  before_action :authorize_admin_group!

  layout 'group_settings'

  def index
    @projects = all_projects.with_shared_runners_limit_enabled.page(params[:page])
  end

  private

  def all_projects
    if Feature.enabled?(:account_on_namespace)
      @group.all_projects
    else
      @group.projects
    end
  end
end
