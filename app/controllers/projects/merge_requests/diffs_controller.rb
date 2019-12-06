# frozen_string_literal: true

class Projects::MergeRequests::DiffsController < Projects::MergeRequests::ApplicationController
  include DiffHelper
  include RendersNotes

  before_action :apply_diff_view_cookie!
  before_action :commit, except: :diffs_batch
  before_action :define_diff_vars, except: :diffs_batch
  before_action :define_diff_comment_vars, except: [:diffs_batch, :diffs_metadata]

  def show
    render_diffs
  end

  def diff_for_path
    render_diffs
  end

  def diffs_batch
    return render_404 unless Feature.enabled?(:diffs_batch_load, @merge_request.project)

    diffable = @merge_request.merge_request_diff

    return render_404 unless diffable

    diffs = diffable.diffs_in_batch(params[:page], params[:per_page], diff_options: diff_options)
    positions = @merge_request.note_positions_for_paths(diffs.diff_file_paths, current_user)

    diffs.unfold_diff_files(positions.unfoldable)
    diffs.write_cache

    options = {
      merge_request: @merge_request,
      diff_view: diff_view,
      pagination_data: diffs.pagination_data
    }

    render json: PaginatedDiffSerializer.new(current_user: current_user).represent(diffs, options)
  end

  def diffs_metadata
    render json: DiffsMetadataSerializer.new(project: @merge_request.project)
                   .represent(@diffs, additional_attributes)
  end

  private

  def preloadable_mr_relations
    [{ source_project: :namespace }, { target_project: :namespace }]
  end

  def render_diffs
    @environment = @merge_request.environments_for(current_user).last

    @diffs.unfold_diff_files(note_positions.unfoldable)
    @diffs.write_cache

    request = {
      current_user: current_user,
      project: @merge_request.project,
      render: ->(partial, locals) { view_to_html_string(partial, locals) }
    }

    options = additional_attributes.merge(diff_view: diff_view)

    render json: DiffsSerializer.new(request).represent(@diffs, options)
  end

  def define_diff_vars
    @merge_request_diffs = @merge_request.merge_request_diffs.viewable.order_id_desc
    @compare = commit || find_merge_request_diff_compare
    return render_404 unless @compare

    @diffs = @compare.diffs(diff_options)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def commit
    return unless commit_id = params[:commit_id].presence
    return unless @merge_request.all_commits.exists?(sha: commit_id)

    @commit ||= @project.commit(commit_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
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
  # rubocop: enable CodeReuse/ActiveRecord

  def additional_attributes
    {
      environment: @environment,
      merge_request: @merge_request,
      merge_request_diff: @merge_request_diff,
      merge_request_diffs: @merge_request_diffs,
      start_version: @start_version,
      start_sha: @start_sha,
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

  def note_positions
    @note_positions ||= Gitlab::Diff::PositionCollection.new(renderable_notes.map(&:position))
  end

  def renderable_notes
    define_diff_comment_vars unless @notes

    @notes
  end
end

Projects::MergeRequests::DiffsController.prepend_if_ee('EE::Projects::MergeRequests::DiffsController')
