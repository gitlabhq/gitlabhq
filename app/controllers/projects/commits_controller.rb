# frozen_string_literal: true

require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath
  include RendersCommits

  COMMITS_DEFAULT_LIMIT = 40
  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:rss) }
  around_action :allow_gitaly_ref_name_caching
  before_action :require_non_empty_project
  before_action :assign_ref_vars, except: :commits_root
  before_action :authorize_read_code!
  before_action :validate_ref!, except: :commits_root
  before_action :set_commits, except: :commits_root

  feature_category :source_code_management
  urgency :low, [:signatures, :show]

  def commits_root
    redirect_to project_commits_path(@project, @project.default_branch)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @merge_request = MergeRequestsFinder.new(current_user, project_id: @project.id).execute.opened
      .find_by(source_project: @project, source_branch: @ref, target_branch: @repository.root_ref)

    @ref_type = ref_type

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml' }

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

    limit = permitted_params[:limit].to_i
    @limit = limit > 0 ? limit : COMMITS_DEFAULT_LIMIT # limit can only ever be a positive number
    @offset = (permitted_params[:offset] || 0).to_i
    search = permitted_params[:search]
    author = permitted_params[:author]

    # fully_qualified_ref is available in some situations from ExtractsRef
    ref = @fully_qualified_ref || @ref

    @commits =
      if search.present?
        @repository.find_commits_by_message(search, ref, @path, @limit, @offset)
      else
        options = {
          path: @path,
          limit: @limit,
          offset: @offset
        }
        options[:author] = author if author.present?

        @repository.commits(ref, **options)
      end

    @commits.load_tags
    @commits.each(&:lazy_author) # preload authors

    @commits = @commits.with_markdown_cache.with_latest_pipeline(ref)
    @commits = set_commits_for_rendering(@commits)
  end

  def permitted_params
    params.permit(:limit, :offset, :search, :author)
  end
end
