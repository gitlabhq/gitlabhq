module Notes
  class CreateService < BaseService
    def execute
      create_award_emoji = params.delete(:create_award_emoji)

      note = project.notes.new(params)

      note.author = current_user
      note.system = false

      if create_award_emoji && note.emoji_award?
        note.create_award_emoji
        return note
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
