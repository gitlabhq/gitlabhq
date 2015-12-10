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
    diff_options = { ignore_whitespace_change: true } if params[:w] == '1'

    compare_result = CompareService.new.
      execute(@project, head_ref, @project, base_ref, diff_options)

    if compare_result
      @commits = Commit.decorate(compare_result.commits, @project)
      @diffs = compare_result.diffs
      @commit = @project.commit(head_ref)
      @first_commit = @project.commit(base_ref)
      @line_notes = []
    end
  end

  def create
    redirect_to namespace_project_compare_path(@project.namespace, @project,
                                               params[:from], params[:to])
  end
end
