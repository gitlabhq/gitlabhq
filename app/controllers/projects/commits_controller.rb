# frozen_string_literal: true

require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath
  include RendersCommits
  include ParseCommitDate
  include RedirectsForMissingPathOnTree

  COMMITS_DEFAULT_LIMIT = 40
  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:rss) }
  around_action :allow_gitaly_ref_name_caching
  before_action :require_non_empty_project
  before_action :assign_ref_vars, except: :commits_root
  before_action :authorize_read_code!
  before_action :validate_ref!, except: :commits_root
  before_action :validate_path, if: -> { !request.format.atom? }
  before_action :set_is_ambiguous_ref, only: [:show]
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

  def validate_path
    return unless @path

    path_exists = @repository.blob_at(@commit.id, @path) || @repository.tree(@commit.id, @path).entries.present?
    redirect_to_tree_root_for_missing_path(@project, @ref, @path) unless path_exists
  end

  def set_commits
    limit = permitted_params[:limit].to_i
    @limit = limit > 0 ? limit : COMMITS_DEFAULT_LIMIT # limit can only ever be a positive number
    @offset = (permitted_params[:offset] || 0).to_i
    search = permitted_params[:search]
    author = permitted_params[:author]
    committed_before = convert_date_to_epoch(permitted_params[:committed_before])
    committed_after = convert_date_to_epoch(permitted_params[:committed_after])

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
        options[:before] = committed_before if committed_before.present?
        options[:after] = committed_after if committed_after.present?

        @repository.commits(ref, **options)
      end

    @commits.load_tags
    @commits.each(&:lazy_author) # preload authors

    @commits = @commits.with_markdown_cache.with_latest_pipeline(ref)
    @commits = set_commits_for_rendering(@commits)
  end

  def permitted_params
    params.permit(:limit, :offset, :search, :author, :committed_before, :committed_after)
  end
end
