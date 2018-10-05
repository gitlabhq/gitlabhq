class Groups::PipelineQuotaController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :validate_shared_runner_minutes_support!

  layout 'group_settings'

  def index
    @projects = all_projects.with_shared_runners_limit_enabled.page(params[:page])
  end

  private

  def all_projects
    if ::Feature.enabled?(:shared_runner_minutes_on_root_namespace)
      @group.all_projects
    else
      @group.projects
    end
  end

  def validate_shared_runner_minutes_support!
    render_404 unless @group.shared_runner_minutes_supported?
  end
end
