module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.award_emoji?
        noteable = note.noteable
        todo_service.new_award_emoji(noteable, current_user)
        return noteable.create_award_emoji(note.award_emoji_name, current_user)
      end

      if note.save
        # Finish the harder work in the background
        NewNoteWorker.perform_in(2.seconds, note.id, params)
        TodoService.new.new_note(note, current_user)
      end

      note
    end
  end
end
