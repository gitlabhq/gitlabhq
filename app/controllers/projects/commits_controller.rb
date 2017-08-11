require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars, only: :show
  before_action :authorize_download_code!

  def show
    @limit, @offset = (params[:limit] || 40).to_i, (params[:offset] || 0).to_i
    search = params[:search]

    @commits =
      if search.present?
        @repository.find_commits_by_message(search, @ref, @path, @limit, @offset)
      else
        @repository.commits(@ref, path: @path, limit: @limit, offset: @offset)
      end

    @note_counts = project.notes.where(commit_id: @commits.map(&:id))
      .group(:commit_id).count

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
    commit_ids = Array(params[:sha])

    signatures = GpgSignature.where(commit_sha: commit_ids)

    # Filter commits without GpgSignature record in the database
    # but with signature in git and create missing GpgSignature objects by
    # invoking `signature` method on those
    commit_ids = commit_ids - signatures.map(&:commit_sha)
    commits = commit_ids.map { |sha| @repository.commit(sha) }
    signatures += commits.select(&:has_signature?).map(&:signature)

    render json: {
      signatures: signatures.map do |signature|
        {
          commit_sha: signature.commit_sha,
          html: view_to_html_string('projects/commit/_signature', signature: signature)
        }
      end
    }
  end
end
