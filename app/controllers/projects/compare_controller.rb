require 'addressable/uri'

class Projects::CompareController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!

  def index
    @ref = Addressable::URI.unescape(params[:to])
  end

  def show
    base_ref = Addressable::URI.unescape(params[:from])
    @ref = head_ref = Addressable::URI.unescape(params[:to])

    compare_result = CompareService.new.
      execute(@project, head_ref, @project, base_ref)

    if compare_result
      @commits = Commit.decorate(compare_result.commits, @project)
      @diffs = compare_result.diffs
      @commit = @commits.last
      @first_commit = @commits.first
      @line_notes = []
    end
  end

  def create
    redirect_to namespace_project_compare_path(@project.namespace, @project,
                                               params[:from], params[:to])
  end
end
