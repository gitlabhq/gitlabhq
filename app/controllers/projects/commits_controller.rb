require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @limit, @offset = (params[:limit] || 40).to_i, (params[:offset] || 0).to_i
    search = params[:search]

    @commits =
      if search.present?
        @repository.find_commits_by_message(search, @ref, @path, @limit, @offset).compact
      else
        @repository.commits(@ref, @path, @limit, @offset)
      end

    @note_counts = project.notes.where(commit_id: @commits.map(&:id)).
      group(:commit_id).count

    @merge_request = @project.merge_requests.opened.
      find_by(source_project: @project, source_branch: @ref, target_branch: @repository.root_ref)

    respond_to do |format|
      format.html
      format.json { pager_json("projects/commits/_commits", @commits.size) }
      format.atom { render layout: false }
    end
  end
end
