# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::Projects::ApplicationController < Admin::ApplicationController

  protected

  def project
    @project ||= Project.find_with_namespace(params[:project_id])
  end
end
