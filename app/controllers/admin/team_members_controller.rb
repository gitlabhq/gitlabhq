class Admin::TeamMembersController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_team_members = UsersProject.page(params[:page]).per(100).order("project_id DESC")
  end

  def show
    @admin_team_member = UsersProject.find(params[:id])
  end

  def new
    @admin_team_member = UsersProject.new(params[:team_member])
  end

  def edit
    @admin_team_member = UsersProject.find(params[:id])
  end

  def create
    @admin_team_member = UsersProject.new(params[:team_member])
    @admin_team_member.project_id = params[:team_member][:project_id]

    if @admin_team_member.save
      redirect_to admin_team_member_path(@admin_team_member), notice: 'UsersProject was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    @admin_team_member = UsersProject.find(params[:id])
    @admin_team_member.project_id = params[:team_member][:project_id]

    if @admin_team_member.update_attributes(params[:team_member])
      redirect_to admin_team_member_path(@admin_team_member), notice: 'UsersProject was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @admin_team_member = UsersProject.find(params[:id])
    @admin_team_member.destroy

    redirect_to admin_team_members_url
  end
end
