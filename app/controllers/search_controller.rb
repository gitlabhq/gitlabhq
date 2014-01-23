class SearchController < ApplicationController
  include SearchHelper

  def show
    @project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
    @group = Group.find_by(id: params[:group_id]) if params[:group_id].present?

    if @project
      return access_denied! unless can?(current_user, :download_code, @project)
      @search_results = Search::ProjectService.new(@project, current_user, params).execute
    else
      @search_results = Search::GlobalService.new(current_user, params).execute
    end
  end

  def autocomplete
    term = params[:term]
    @project = Project.find(params[:project_id]) if params[:project_id].present?
    @ref = params[:project_ref] if params[:project_ref].present?

    render json: search_autocomplete_opts(term).to_json
  end
end
