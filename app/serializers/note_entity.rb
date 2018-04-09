class NoteEntity < API::Entities::Note
  include RequestAwareEntity
  include NotesHelper

  expose :type

  expose :author, using: NoteUserEntity

  unexpose :note, as: :body
  expose :note

  expose :redacted_note_html, as: :note_html

  expose :last_edited_at, if: -> (note, _) { note.edited? }
  expose :last_edited_by, using: NoteUserEntity, if: -> (note, _) { note.edited? }

  expose :current_user do
    expose :can_edit do |note|
      Ability.can_edit_note?(request.current_user, note)
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

  expose :path do |note|
    if note.for_personal_snippet?
      snippet_note_path(note.noteable, note)
    else
      project_note_path(note.project, note)
    end
  end

  expose :noteable_note_url do |note|
    noteable_note_url(note)
  end

  expose :resolve_path, if: -> (note, _) { note.part_of_discussion? && note.resolvable? } do |note|
    resolve_project_merge_request_discussion_path(note.project, note.noteable, note.discussion_id)
  end

  expose :resolve_with_issue_path, if: -> (note, _) { note.part_of_discussion? && note.resolvable? } do |note|
    new_project_issue_path(note.project, merge_request_to_resolve_discussions_of: note.noteable.iid, discussion_to_resolve: note.discussion_id)
  end

  expose :attachment, using: NoteAttachmentEntity, if: -> (note, _) { note.attachment? }
end
