class ProjectNoteEntity < NoteEntity
  expose :human_access do |note|
    note.project.team.human_max_access(note.author_id)
  end

  expose :toggle_award_path, if: -> (note, _) { note.emoji_awardable? } do |note|
    toggle_award_emoji_project_note_path(note.project, note.id)
  end

  expose :path do |note|
    project_note_path(note.project, note)
  end

  expose :resolve_path, if: -> (note, _) { note.part_of_discussion? && note.resolvable? } do |note|
    resolve_project_merge_request_discussion_path(note.project, note.noteable, note.discussion_id)
  end

  expose :resolve_with_issue_path, if: -> (note, _) { note.part_of_discussion? && note.resolvable? } do |note|
    new_project_issue_path(note.project, merge_request_to_resolve_discussions_of: note.noteable.iid, discussion_to_resolve: note.discussion_id)
  end

  expose :delete_attachment_path, if: -> (note, _) { note.attachment? } do |note|
    delete_attachment_project_note_path(note.project, note)
  end
end
