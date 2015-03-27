class AutocompleteController < ApplicationController
  def users
    @users =
      if params[:project_id].present?
        project = Project.find(params[:project_id])

        if can?(current_user, :read_project, project)
          project.team.users
        end
      elsif params[:group_id]
        group = Group.find(params[:group_id])

        if can?(current_user, :read_group, group)
          group.users
        end
      else
        User.all
      end

    @users = @users.search(params[:search]) if params[:search].present?
    @users = @users.active
    @users = @users.page(params[:page]).per(PER_PAGE)
    render json: @users, only: [:name, :username, :id], methods: [:avatar_url]
  end

  def user
    @user = User.find(params[:id])
    render json: @user, only: [:name, :username, :id], methods: [:avatar_url]
  end
end
