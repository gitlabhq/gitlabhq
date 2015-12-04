class AutocompleteController < ApplicationController
  skip_before_action :authenticate_user!, only: [:users]
  before_action :find_users, only: [:users]

  def users
    @users ||= User.none
    @users = @users.search(params[:search]) if params[:search].present?
    @users = @users.active
    @users = @users.reorder(:name)
    @users = @users.page(params[:page]).per(PER_PAGE)

    if params[:search].blank?
      # Include current user if available to filter by "Me"
      if params[:current_user] && current_user
        @users = [*@users, current_user].uniq
      end
    end

    render json: @users, only: [:name, :username, :id], methods: [:avatar_url]
  end

  def user
    @user = User.find(params[:id])
    render json: @user, only: [:name, :username, :id], methods: [:avatar_url]
  end

  private

  def find_users
    @users =
      if params[:project_id].present?
        project = Project.find(params[:project_id])
        return render_404 unless can?(current_user, :read_project, project)

        project.team.users
      elsif params[:group_id].present?
        group = Group.find(params[:group_id])
        return render_404 unless can?(current_user, :read_group, group)

        group.users
      elsif current_user
        User.all
      else
        User.none
      end
  end
end
