class Groups::Epics::NotesController < Groups::ApplicationController
  include NotesActions
  include NotesHelper
  include ToggleAwardEmoji

  before_action :epic
  before_action :authorize_create_note!, only: [:create]

  private

  def project
    nil
  end

  def note
    @note ||= noteable.notes.find(params[:id])
  end
  alias_method :awardable, :note

  def epic
    @epic ||= @group.epics.find_by(iid: params[:epic_id])

    return render_404 unless can?(current_user, :read_epic, @epic)

    @epic
  end
  alias_method :noteable, :epic

  def finder_params
    params.merge(last_fetched_at: last_fetched_at, target_id: epic.id, target_type: 'epic', group_id: @group.id)
  end

  def authorize_create_note!
    access_denied! unless can?(current_user, :create_note, noteable)
  end

  def note_serializer
    EpicNoteSerializer.new(project: nil, noteable: noteable, current_user: current_user)
  end
end
