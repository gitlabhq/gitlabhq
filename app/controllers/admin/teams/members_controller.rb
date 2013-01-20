class Admin::Teams::MembersController < Admin::Teams::ApplicationController
  def new
    @users = User.active
    @users = @users.not_in_team(@team) if @team.members.any?
    @users = UserDecorator.decorate @users
  end

  def create
    unless params[:user_ids].blank?
      user_ids = params[:user_ids]
      access = params[:default_project_access]
      is_admin = params[:group_admin]
      @team.add_members(user_ids, access, is_admin)
    end

    redirect_to admin_team_path(@team), notice: 'Members was successfully added.'
  end

  def edit
    @member = @team.members.find(params[:id])
  end

  def update
    @member = @team.members.find(params[:id])
    options = {default_projects_access: params[:default_project_access], group_admin: params[:group_admin]}
    if @team.update_membership(@member, options)
      redirect_to admin_team_path(@team), notice: 'Membership was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
  end
end
