class Admin::Projects::MembersController < Admin::Projects::ApplicationController
  def destroy
    team_member_relation.destroy

    redirect_to :back
  end

  private

  def team_member
    @member ||= project.users.find_by_username(params[:id])
  end

  def team_member_relation
    team_member.users_projects.find_by_project_id(project)
  end
end
