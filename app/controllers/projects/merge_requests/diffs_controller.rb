class Projects::MergeRequests::DiffsController < Projects::MergeRequests::ApplicationController
  include DiffForPath
  include DiffHelper
  include NotesHelper
  include RendersNotes

  before_action :apply_diff_view_cookie!
  before_action :commit
  before_action :define_diff_vars
  before_action :define_diff_comment_vars

  def show
    @environment = @merge_request.environments_for(current_user).last

    if has_vue_discussions_cookie?
      render json: DiffsSerializer.new.represent(@diffs, serializeable_vars)
    else
      render json: { html: view_to_html_string("projects/merge_requests/diffs/_diffs") }
    end
  end

  def diff_for_path
    render_diff_for_path(@diffs)
  end

  private

  def define_diff_vars
    @merge_request_diffs = @merge_request.merge_request_diffs.viewable.order_id_desc
    @compare = commit || find_merge_request_diff_compare
    return render_404 unless @compare

    @diffs = @compare.diffs(diff_options)
  end

  def commit
    return nil unless commit_id = params[:commit_id].presence
    return nil unless @merge_request.all_commits.exists?(sha: commit_id)

    @commit ||= @project.commit(commit_id)
  end

  def find_merge_request_diff_compare
    @merge_request_diff =
      if diff_id = params[:diff_id].presence
        @merge_request.merge_request_diffs.viewable.find_by(id: diff_id)
      else
        @merge_request.merge_request_diff
      end

    return unless @merge_request_diff

    @comparable_diffs = @merge_request_diffs.select { |diff| diff.id < @merge_request_diff.id }

    if @start_sha = params[:start_sha].presence
      @start_version = @comparable_diffs.find { |diff| diff.head_commit_sha == @start_sha }

      unless @start_version
        @start_sha = @merge_request_diff.head_commit_sha
        @start_version = @merge_request_diff
      end
    end

    if @start_sha
      @merge_request_diff.compare_with(@start_sha)
    else
      @merge_request_diff
    end
  end

  def serializeable_vars
    {
      merge_request: @merge_request,
      merge_request_diffs: @merge_request_diffs,
      start_version: @start_version,
      commit: @commit,
      latest_diff: @merge_request_diff&.latest?
    }
  end

  def define_diff_comment_vars
    @new_diff_note_attrs = {
      noteable_type: 'MergeRequest',
      noteable_id: @merge_request.id,
      commit_id: @commit&.id
    }

    @diff_notes_disabled = false

    @use_legacy_diff_notes = !@merge_request.has_complete_diff_refs?

    @grouped_diff_discussions = @merge_request.grouped_diff_discussions(@compare.diff_refs)
    @notes = prepare_notes_for_rendering(@grouped_diff_discussions.values.flatten.flat_map(&:notes), @merge_request)
  end
end
