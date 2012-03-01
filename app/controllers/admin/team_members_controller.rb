class Admin::TeamMembersController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def edit
    @admin_team_member = UsersProject.find(params[:id])
  end

  def update
    @admin_team_member = UsersProject.find(params[:id])

    if @admin_team_member.update_attributes(params[:team_member])
      redirect_to [:admin, @admin_team_member.project],  notice: 'Project Access was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @admin_team_member = UsersProject.find(params[:id])
    @admin_team_member.destroy

    redirect_to :back
  end
end
