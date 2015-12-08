require "base64"

class Projects::CommitsController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @repo = @project.repository
    @limit, @offset = (params[:limit] || 40), (params[:offset] || 0)

    @commits = @repo.commits(@ref, @path, @limit, @offset)
    @note_counts = project.notes.where(commit_id: @commits.map(&:id)).
      group(:commit_id).count

    respond_to do |format|
      format.html
      format.json { pager_json("projects/commits/_commits", @commits.size) }
      format.atom { render layout: false }
    end
  end
end
