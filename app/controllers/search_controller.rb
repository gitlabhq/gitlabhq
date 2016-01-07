class SearchController < ApplicationController
  include SearchHelper

  layout 'search'

  def show
    return if params[:search].nil? || params[:search].blank?

    @search_term = params[:search]

    if params[:project_id].present?
      @project = Project.find_by(id: params[:project_id])
      @project = nil unless can?(current_user, :download_code, @project)
    end

    if params[:group_id].present?
      @group = Group.find_by(id: params[:group_id])
      @group = nil unless can?(current_user, :read_group, @group)
    end

    @scope = params[:scope]
    @show_snippets = params[:snippets].eql? 'true'

    @search_results =
      if @project
        unless %w(blobs notes issues merge_requests milestones wiki_blobs
                  commits).include?(@scope)
          @scope = 'blobs'
        end

        Search::ProjectService.new(@project, current_user, params).execute
      elsif @show_snippets
        unless %w(snippet_blobs snippet_titles).include?(@scope)
          @scope = 'snippet_blobs'
        end

        Search::SnippetService.new(current_user, params).execute
      else
        unless %w(projects issues merge_requests milestones).include?(@scope)
          @scope = 'projects'
        end
        Search::GlobalService.new(current_user, params).execute
      end

    @objects = @search_results.objects(@scope, params[:page])
  end

  def autocomplete
    term = params[:term]

    if params[:project_id].present?
      @project = Project.find_by(id: params[:project_id])
      @project = nil unless can?(current_user, :read_project, @project)
    end

    @ref = params[:project_ref] if params[:project_ref].present?

    render json: search_autocomplete_opts(term).to_json
  end
end
