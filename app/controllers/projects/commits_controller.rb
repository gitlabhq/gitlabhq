require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath
  include RendersCommits

  before_action :whitelist_query_limiting, except: :commits_root
  before_action :require_non_empty_project
  before_action :assign_ref_vars, except: :commits_root
  before_action :authorize_download_code!
  before_action :set_commits, except: :commits_root
  before_action :set_request_format, only: :show

  def commits_root
    redirect_to project_commits_path(@project, @project.default_branch)
  end

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

  def set_commits
    render_404 unless @path.empty? || request.format == :atom || @repository.blob_at(@commit.id, @path) || @repository.tree(@commit.id, @path).entries.present?
    @limit, @offset = (params[:limit] || 40).to_i, (params[:offset] || 0).to_i
    search = params[:search]

    @commits =
      if search.present?
        @repository.find_commits_by_message(search, @ref, @path, @limit, @offset)
      else
        @repository.commits(@ref, path: @path, limit: @limit, offset: @offset)
      end

    @commits = @commits.with_pipeline_status
    @commits = prepare_commits_for_rendering(@commits)
  end

  # Rails 5 sets request.format from the extension.
  # Explicitly set to :html.
  def set_request_format
    request.format = :html if set_request_format?
  end

  # Rails 5 sets request.format from extension.
  # In this case if the ref ends with `.atom`, it's expected to be the html response,
  # not the atom one. So explicitly set request.format as :html to act like rails4.
  def set_request_format?
    request.format.to_s == "text/html" || @commits.ref.ends_with?("atom")
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42330')
  end
end
