class Groups::PipelineQuotaController < Groups::ApplicationController
  before_action :authorize_admin_group!

  layout 'group_settings'

  def index
    @projects = @group.projects.where(shared_runners_enabled: true).page(params[:page])
  end
end
