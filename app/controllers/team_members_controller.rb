class TeamMembersController < ApplicationController
  before_filter :project 

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_team_member!
  before_filter :authorize_admin_team_member!, :only => [:new, :create, :destroy, :update] 

  def show
    @team_member = project.users_projects.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.js
      format.json { render json: @team_member }
    end
  end

  def new
    @team_member = project.users_projects.new

    respond_to do |format|
      format.html # new.html.erb
      format.js
      format.json { render json: @team_member }
    end
  end

  def create
    @team_member = UsersProject.new(params[:team_member])
    @team_member.project = project

    respond_to do |format|
      if @team_member.save
        format.html { redirect_to @team_member, notice: 'Team member was successfully created.' }
        format.js
        format.json { render json: @team_member, status: :created, location: @team_member }
      else
        format.html { render action: "new" }
        format.js
        format.json { render json: @team_member.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @team_member = project.users_projects.find(params[:id])
    @team_member.update_attributes(params[:team_member])

    respond_to do |format|
      format.js
      format.html { redirect_to team_project_path(@project)}
    end
  end

  def destroy
    @team_member = project.users_projects.find(params[:id])
    @team_member.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :ok }
      format.js { render :nothing => true }  
    end
  end
end
