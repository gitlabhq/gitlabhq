class Groups::ProjectsController < Groups::ApplicationController
  # Authorize
  before_action :authorize_admin_group!

  layout 'group_settings'

  def edit
    @projects = @group.projects.page(params[:page])
  end

end
