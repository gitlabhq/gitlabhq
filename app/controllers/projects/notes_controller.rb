# frozen_string_literal: true

class Projects::NotesController < Projects::ApplicationController
  extend Gitlab::Utils::Override
  include RendersNotes
  include NotesActions
  include NotesHelper
  include ToggleAwardEmoji

  before_action :disable_query_limiting, only: [:create, :update]
  before_action :disable_query_limiting_index, only: [:index]

  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_resolve_note!, only: [:resolve, :unresolve]

  feature_category :team_planning, [:index, :create, :update, :destroy, :delete_attachment, :toggle_award_emoji]
  feature_category :code_review_workflow, [:resolve, :unresolve, :outdated_line_change]
  urgency :low

  override :feature_category
  def feature_category
    if %w[index create].include?(params[:action])
      category = feature_category_override_for_target_type(params[:target_type])
      return category if category
    end

    super
  end

  def feature_category_override_for_target_type(target_type)
    case target_type
    when 'merge_request'
      'code_review_workflow'
    when 'commit', 'project_snippet'
      'source_code_management'
    end
  end

  def delete_attachment
    note.remove_attachment!
    note.update_attribute(:attachment, nil)

    respond_to do |format|
      format.js { head :ok }
    end
  end

  def resolve
    return render_404 unless note.resolvable?

    Notes::ResolveService.new(project, current_user).execute(note)

    render_json_with_notes_serializer
  end

  def unresolve
    return render_404 unless note.resolvable?

    note.unresolve!

    render_json_with_notes_serializer
  end

  def outdated_line_change
    diff_lines = Rails.cache.fetch(['note', note.id, 'oudated_line_change'], expires_in: 7.days) do
      Gitlab::Json.dump(::MergeRequests::OutdatedDiscussionDiffLinesService.new(project: note.noteable.source_project, note: note).execute)
    end

    render json: diff_lines
  end

  private

  def render_json_with_notes_serializer
    prepare_notes_for_rendering([note])

    render json: note_serializer.represent(note, render_truncated_diff_lines: true)
  end

  def note
    @note ||= @project.notes.find(params[:id])
  end

  alias_method :awardable, :note

  def finder_params
    params.merge(project: project, last_fetched_at: last_fetched_at, notes_filter: notes_filter)
  end

  def authorize_admin_note!
    access_denied! unless can?(current_user, :admin_note, note)
  end

  def authorize_resolve_note!
    access_denied! unless can?(current_user, :resolve_note, note)
  end

  def authorize_create_note!
    return unless noteable.lockable?

    access_denied! unless can?(current_user, :create_note, noteable)
  end

  def disable_query_limiting_index
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/460923')
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/211538', new_threshold: 300)
  end
end
