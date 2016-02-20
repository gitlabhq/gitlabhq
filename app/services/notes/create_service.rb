module Notes
  class CreateService < BaseService
    def execute
      create_emoji_awards = params.delete(:create_emoji_awards)

      note = project.notes.new(params)

      note.author = current_user
      note.system = false

      if create_emoji_awards && note.emoji_award?
        note.create_emoji_award
        return note
      end

      if note.save
        # Finish the harder work in the background
        NewNoteWorker.perform_in(2.seconds, note.id, params)
      end

      note
    end

  end
end
