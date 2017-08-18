class Projects::MergeRequests::DiffsController < Projects::MergeRequests::ApplicationController
  include DiffForPath
  include DiffHelper
  include RendersNotes

  before_action :apply_diff_view_cookie!
  before_action :define_diff_vars
  before_action :define_diff_comment_vars

  def show
    @environment = @merge_request.environments_for(current_user).last

    render json: { html: view_to_html_string("projects/merge_requests/diffs/_diffs") }
  end

  def diff_for_path
    render_diff_for_path(@diffs)
  end

  private

  def define_diff_vars
    @merge_request_diff =
      if params[:diff_id]
        @merge_request.merge_request_diffs.viewable.find(params[:diff_id])
      else
        @merge_request.merge_request_diff
      end

    @merge_request_diffs = @merge_request.merge_request_diffs.viewable.select_without_diff
    @comparable_diffs = @merge_request_diffs.select { |diff| diff.id < @merge_request_diff.id }

    if params[:start_sha].present?
      @start_sha = params[:start_sha]
      @start_version = @comparable_diffs.find { |diff| diff.head_commit_sha == @start_sha }

      unless @start_version
        @start_sha = @merge_request_diff.head_commit_sha
        @start_version = @merge_request_diff
      end
    end

    @compare =
      if @start_sha
        @merge_request_diff.compare_with(@start_sha)
      else
        @merge_request_diff
      end

    @diffs = @compare.diffs(diff_options)
  end

  def define_diff_comment_vars
    @new_diff_note_attrs = {
      noteable_type: 'MergeRequest',
      noteable_id: @merge_request.id
    }

    @diff_notes_disabled = false

    @use_legacy_diff_notes = !@merge_request.has_complete_diff_refs?

    @grouped_diff_discussions = @merge_request.grouped_diff_discussions(@compare.diff_refs)
    @notes = prepare_notes_for_rendering(@grouped_diff_discussions.values.flatten.flat_map(&:notes))
  end
end
