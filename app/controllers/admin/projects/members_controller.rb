class Admin::Projects::MembersController < Admin::Projects::ApplicationController
  def edit
    @member = team_member
    @project = project
    @team_member_relation = team_member_relation
  end

  def update
    if team_member_relation.update_attributes(params[:team_member])
      redirect_to [:admin, project],  notice: 'Project Access was successfully updated.'
    else
      render action: "edit"
    end
  end

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
