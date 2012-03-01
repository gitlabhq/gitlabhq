class TeamMembersController < ApplicationController
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_admin_project!, :except => [:show]

  def show
    @team_member = project.users_projects.find(params[:id])
  end

  def new
    @team_member = project.users_projects.new
  end

  def create
    @team_member = UsersProject.new(params[:team_member])
    @team_member.project = project
    if @team_member.save
      redirect_to team_project_path(@project)
    else
      render "new"
    end
  end

  def update
    @team_member = project.users_projects.find(params[:id])
    @team_member.update_attributes(params[:team_member])

    unless @team_member.valid?
      flash[:alert] = "User should have at least one role"
    end
    redirect_to team_project_path(@project)
  end

  def destroy
    @team_member = project.users_projects.find(params[:id])
    @team_member.destroy

    respond_to do |format|
      format.html { redirect_to team_project_path(@project) }
      format.js { render :nothing => true }
    end
  end
end
