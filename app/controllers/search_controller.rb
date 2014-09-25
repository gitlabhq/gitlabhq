class SearchController < ApplicationController
  include SearchHelper

  def show
    @project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
    @group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
    @scope = params[:scope]
    @show_snippets = params[:snippets].eql? 'true'

    @search_results = if @project
                        return access_denied! unless can?(current_user, :download_code, @project)

                        unless %w(blobs notes issues merge_requests wiki_blobs).
                                 include?(@scope)
                          @scope = 'blobs'
                        end

                        Search::ProjectService.new(@project, current_user, params).execute
                      elsif @show_snippets
                        unless %w(snippet_blobs snippet_titles).include?(@scope)
                          @scope = 'snippet_blobs'
                        end

                        Search::SnippetService.new(current_user, params).execute
                      else
                        unless %w(projects issues merge_requests).include?(@scope)
                          @scope = 'projects'
                        end

                        Search::GlobalService.new(current_user, params).execute
                      end

    @objects = @search_results.objects(@scope, params[:page])
  end

  def autocomplete
    term = params[:term]
    @project = Project.find(params[:project_id]) if params[:project_id].present?
    @ref = params[:project_ref] if params[:project_ref].present?

    render json: search_autocomplete_opts(term).to_json
  end
end
