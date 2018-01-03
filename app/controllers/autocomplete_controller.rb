class AutocompleteController < ApplicationController
  AWARD_EMOJI_MAX = 100

  skip_before_action :authenticate_user!, only: [:users, :award_emojis]
  before_action :load_project, only: [:users]
  before_action :load_group, only: [:users]

  def users
    @users = AutocompleteUsersFinder.new(params: params, current_user: current_user, project: @project, group: @group).execute

    render json: UserSerializer.new.represent(@users)
  end

  def user
    @user = User.find(params[:id])
    render json: UserSerializer.new.represent(@user)
  end

  def projects
    project = Project.find_by_id(params[:project_id])
    projects = projects_finder.execute(project, search: params[:search], offset_id: params[:offset_id])

    render json: projects.to_json(only: [:id, :name_with_namespace], methods: :name_with_namespace)
  end

  def award_emojis
    emoji_with_count = AwardEmoji
      .limit(AWARD_EMOJI_MAX)
      .where(user: current_user)
      .group(:name)
      .order('count_all DESC, name ASC')
      .count

    # Transform from hash to array to guarantee json order
    # e.g. { 'thumbsup' => 2, 'thumbsdown' = 1 }
    #   => [{ name: 'thumbsup' }, { name: 'thumbsdown' }]
    render json: emoji_with_count.map { |k, v| { name: k } }
  end

  private

  def load_group
    @group ||= begin
      if @project.blank? && params[:group_id].present?
        group = Group.find(params[:group_id])
        return render_404 unless can?(current_user, :read_group, group)

        group
      end
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
