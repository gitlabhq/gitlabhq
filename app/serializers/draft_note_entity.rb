# frozen_string_literal: true
class DraftNoteEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :author, using: NoteUserEntity
  expose :merge_request_id
  expose :position, if: ->(note, _) { note.on_diff? }
  expose :line_code
  expose :file_identifier_hash
  expose :file_hash
  expose :file_path
  expose :note
  expose :rendered_note, as: :note_html
  expose :references
  expose :discussion_id
  expose :resolve_discussion
  expose :noteable_type
  expose :internal

  expose :current_user do
    expose :can_edit do |note|
      can?(current_user, :admin_note, note)
    end

    expose :can_award_emoji do |note|
      note.emoji_awardable?
    end

    expose :can_resolve do |note|
      note.resolvable? && can?(current_user, :resolve_note, note)
    end
  end

  private

  def current_user
    request.current_user
  end
end
