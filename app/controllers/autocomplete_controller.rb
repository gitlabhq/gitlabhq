class AutocompleteController < ApplicationController
  skip_before_action :authenticate_user!, only: [:users]
  before_action :load_project, only: [:users]
  before_action :find_users, only: [:users]

  def users
    @users = @users.non_ldap if params[:skip_ldap] == 'true'
    @users = @users.search(params[:search]) if params[:search].present?
    @users = @users.where.not(id: params[:skip_users]) if params[:skip_users].present?
    @users = @users.active
    @users = @users.reorder(:name)

    if params[:push_code_to_protected_branches].present? && params[:project_id].present?
      project = Project.find_by(id: params[:project_id])
      @users = @users.to_a.
        select { |user| user.can?(:push_code_to_protected_branches, project) }.
        take(Kaminari.config.default_per_page)
    else
      @users = @users.page(params[:page])
    end

    if params[:search].blank?
      # Include current user if available to filter by "Me"
      if params[:current_user] && current_user
        @users = [*@users, current_user]
      end

      if params[:author_id].present?
        author = User.find_by_id(params[:author_id])
        @users = [author, *@users] if author
      end

      @users.uniq!
    end

    render json: @users, only: [:name, :username, :id], methods: [:avatar_url]
  end

  def user
    @user = User.find(params[:id])
    render json: @user, only: [:name, :username, :id], methods: [:avatar_url]
  end

  def projects
    project = Project.find_by_id(params[:project_id])
    projects = projects_finder.execute(project, search: params[:search], offset_id: params[:offset_id])

    no_project = {
      id: 0,
      name_with_namespace: 'No project',
    }
    projects.unshift(no_project) unless params[:offset_id].present?

    render json: projects.to_json(only: [:id, :name_with_namespace], methods: :name_with_namespace)
  end

  private

  def find_users
    @users =
      if @project
        @project.team.users
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

  def load_project
    @project ||= begin
      if params[:project_id].present?
        project = Project.find(params[:project_id])
        return render_404 unless can?(current_user, :read_project, project)
        project
      end
    end
  end

  def projects_finder
    MoveToProjectFinder.new(current_user)
  end
end
