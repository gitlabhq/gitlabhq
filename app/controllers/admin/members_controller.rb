class Admin::MembersController < Admin::ApplicationController
  def destroy
    user = User.find_by_username(params[:id])
    project = Project.find_with_namespace(params[:project_id])
    project.users_projects.where(user_id: user).first.destroy

    redirect_to :back
  end
end
