class Admin::TeamMembersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_team_members = UsersProject.page(params[:page]).per(100).order("project_id DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_team_members }
    end
  end

  def show
    @admin_team_member = UsersProject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @admin_team_member }
    end
  end

  def new
    @admin_team_member = UsersProject.new(params[:team_member])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_team_member }
    end
  end

  def edit
    @admin_team_member = UsersProject.find(params[:id])
  end

  def create
    @admin_team_member = UsersProject.new(params[:team_member])
    @admin_team_member.project_id = params[:team_member][:project_id]

    respond_to do |format|
      if @admin_team_member.save
        format.html { redirect_to admin_team_member_path(@admin_team_member), notice: 'UsersProject was successfully created.' }
        format.json { render json: @admin_team_member, status: :created, location: @team_member }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_team_member.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @admin_team_member = UsersProject.find(params[:id])
    @admin_team_member.project_id = params[:team_member][:project_id]

    respond_to do |format|
      if @admin_team_member.update_attributes(params[:team_member])
        format.html { redirect_to admin_team_member_path(@admin_team_member), notice: 'UsersProject was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_team_member.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @admin_team_member = UsersProject.find(params[:id])
    @admin_team_member.destroy

    respond_to do |format|
      format.html { redirect_to admin_team_members_url }
      format.json { head :ok }
    end
  end
end
