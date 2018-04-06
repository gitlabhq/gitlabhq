class EpicNoteEntity < NoteEntity
  expose :toggle_award_path, if: -> (note, _) { note.emoji_awardable? } do |note|
    toggle_award_emoji_group_epic_note_path(note.noteable.group, note.noteable, note)
  end

  expose :path do |note|
    group_epic_note_path(note.noteable.group, note.noteable, note)
  end
end
