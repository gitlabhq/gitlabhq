class NoteEntity < API::Entities::Note
  include RequestAwareEntity

  expose :type

  expose :author, using: NoteUserEntity

  unexpose :note, as: :body
  expose :note

  expose :redacted_note_html, as: :note_html

  expose :last_edited_at, if: -> (note, _) { note.edited? }
  expose :last_edited_by, using: NoteUserEntity, if: -> (note, _) { note.edited? }

  expose :current_user do
    expose :can_edit do |note|
      Ability.allowed?(request.current_user, :admin_note, note)
    end
  end

  expose :resolved?, as: :resolved
  expose :resolvable?, as: :resolvable
  expose :resolved_by, using: NoteUserEntity

  expose :system_note_icon_name, if: -> (note, _) { note.system? } do |note|
    SystemNoteHelper.system_note_icon_name(note)
  end

  expose :discussion_id do |note|
    note.discussion_id(request.noteable)
  end

  expose :emoji_awardable?, as: :emoji_awardable
  expose :award_emoji, if: -> (note, _) { note.emoji_awardable? }, using: AwardEmojiEntity

  expose :report_abuse_path do |note|
    new_abuse_report_path(user_id: note.author.id, ref_url: Gitlab::UrlBuilder.build(note))
  end

  expose :attachment, using: NoteAttachmentEntity, if: -> (note, _) { note.attachment? }
end
