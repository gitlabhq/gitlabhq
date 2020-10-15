# frozen_string_literal: true

class Projects::MergeRequests::DraftsController < Projects::MergeRequests::ApplicationController
  include Gitlab::Utils::StrongMemoize

  respond_to :json

  before_action :authorize_create_note!, only: [:create, :publish]
  before_action :authorize_admin_draft!, only: [:update, :destroy]
  before_action :authorize_admin_draft!, if: -> { action_name == 'publish' && params[:id].present? }

  def index
    drafts = prepare_notes_for_rendering(draft_notes)
    render json: DraftNoteSerializer.new(current_user: current_user).represent(drafts)
  end

  def create
    create_params = draft_note_params.merge(in_reply_to_discussion_id: params[:in_reply_to_discussion_id])
    create_service = DraftNotes::CreateService.new(merge_request, current_user, create_params)

    draft_note = create_service.execute

    prepare_notes_for_rendering(draft_note)

    render json: DraftNoteSerializer.new(current_user: current_user).represent(draft_note)
  end

  def update
    draft_note.update!(draft_note_params)

    prepare_notes_for_rendering(draft_note)

    render json: DraftNoteSerializer.new(current_user: current_user).represent(draft_note)
  end

  def destroy
    DraftNotes::DestroyService.new(merge_request, current_user).execute(draft_note)

    head :ok
  end

  def publish
    result = DraftNotes::PublishService.new(merge_request, current_user).execute(draft_note(allow_nil: true))

    if result[:status] == :success
      head :ok
    else
      render json: { message: result[:message] }, status: result[:status]
    end
  end

  def discard
    DraftNotes::DestroyService.new(merge_request, current_user).execute

    head :ok
  end

  private

  def draft_note(allow_nil: false)
    strong_memoize(:draft_note) do
      draft_notes.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound => ex
    # draft_note is allowed to be nil in #publish
    raise ex unless allow_nil
  end

  def draft_notes
    return unless current_user

    strong_memoize(:draft_notes) do
      merge_request.draft_notes.authored_by(current_user)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def merge_request
    @merge_request ||= MergeRequestsFinder.new(current_user, project_id: @project.id).find_by!(iid: params[:merge_request_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def draft_note_params
    params.require(:draft_note).permit(
      :commit_id,
      :note,
      :position,
      :resolve_discussion
    ).tap do |h|
      # Old FE version will still be sending `draft_note[commit_id]` as 'undefined'.
      # That can result to having a note linked to a commit with 'undefined' ID
      # which is non-existent.
      h[:commit_id] = nil if h[:commit_id] == 'undefined'
    end
  end

  def prepare_notes_for_rendering(notes)
    return [] unless notes

    notes = Array.wrap(notes)

    # Preload author and access-level information
    DraftNote.preload_author(notes)
    user_ids = notes.map(&:author_id)
    project.team.max_member_access_for_user_ids(user_ids)

    notes.map(&method(:render_draft_note))
  end

  def render_draft_note(note)
    params = { target_id: merge_request.id, target_type: 'MergeRequest', text: note.note }
    result = PreviewMarkdownService.new(@project, current_user, params).execute
    markdown_params = { markdown_engine: result[:markdown_engine], issuable_state_filter_enabled: true }

    note.rendered_note = view_context.markdown(result[:text], markdown_params)
    note.users_referenced = result[:users]
    note.commands_changes = view_context.markdown(result[:commands])

    note
  end

  def authorize_admin_draft!
    access_denied! unless can?(current_user, :admin_note, draft_note)
  end

  def authorize_create_note!
    access_denied! unless can?(current_user, :create_note, merge_request)
  end
end
