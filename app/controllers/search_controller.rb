class SearchController < ApplicationController
  def show
    @project = Project.find_by_id(params[:project_id]) if params[:project_id].present?
    @group = Group.find_by_id(params[:group_id]) if params[:group_id].present?

    if @project
      return access_denied! unless can?(current_user, :download_code, @project)
      @search_results = Search::ProjectContext.new(@project, current_user, params).execute
    else
      @search_results = Search::GlobalContext.new(current_user, params).execute
    end
  end
end
