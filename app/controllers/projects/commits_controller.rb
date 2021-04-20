# frozen_string_literal: true

require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath
  include RendersCommits

  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:rss) }
  around_action :allow_gitaly_ref_name_caching
  before_action :require_non_empty_project
  before_action :assign_ref_vars, except: :commits_root
  before_action :authorize_download_code!
  before_action :validate_ref!, except: :commits_root
  before_action :set_commits, except: :commits_root

  feature_category :source_code_management

  def commits_root
    redirect_to project_commits_path(@project, @project.default_branch)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).execute.opened
      .find_by(source_project: @project, source_branch: @ref, target_branch: @repository.root_ref)

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml.atom' }

      format.json do
        pager_json(
          'projects/commits/_commits',
          @commits.size,
          project: @project,
          ref: @ref)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def signatures
    respond_to do |format|
      format.json do
        render json: {
          signatures: @commits.select(&:has_signature?).map do |commit|
            {
              commit_sha: commit.sha,
              html: view_to_html_string('projects/commit/_signature', signature: commit.signature)
            }
          end
        }
      end
    end
  end

  private

  def validate_ref!
    render_404 unless valid_ref?(@ref)
  end

  def set_commits
    render_404 unless @path.empty? || request.format == :atom || @repository.blob_at(@commit.id, @path) || @repository.tree(@commit.id, @path).entries.present?
    @limit = (params[:limit] || 40).to_i
    @offset = (params[:offset] || 0).to_i
    search = params[:search]
    author = params[:author]

    @commits =
      if search.present?
        @repository.find_commits_by_message(search, @ref, @path, @limit, @offset)
      elsif author.present?
        @repository.commits(@ref, author: author, path: @path, limit: @limit, offset: @offset)
      else
        @repository.commits(@ref, path: @path, limit: @limit, offset: @offset)
      end

    @commits.each(&:lazy_author) # preload authors

    @commits = @commits.with_latest_pipeline(@ref)
    @commits = set_commits_for_rendering(@commits)
  end
end
