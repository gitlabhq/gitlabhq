# frozen_string_literal: true

class ProjectNoteEntity < NoteEntity
  expose :human_access, if: ->(note, _) { note.project.present? } do |note|
    note.project.team.human_max_access(note.author_id)
  end

  expose :is_contributor, if: ->(note, _) { note.project.present? } do |note|
    note.contributor?
  end

  expose :project_name, if: ->(note, _) { note.project.present? } do |note|
    note.project.name
  end

  expose :toggle_award_path, if: ->(note, _) { note.emoji_awardable? } do |note|
    toggle_award_emoji_project_note_path(note.project, note.id)
  end

  expose :path, if: ->(note, _) { note.id } do |note|
    project_note_path(note.project, note)
  end

  expose :delete_attachment_path, if: ->(note, _) { note.attachment? } do |note|
    delete_attachment_project_note_path(note.project, note)
  end
end
