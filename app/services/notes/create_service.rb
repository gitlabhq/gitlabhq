module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.save
        notification_service.new_note(note)

        # Skip system notes, like status changes and cross-references and awards
        unless note.system || note.is_award
          event = event_service.leave_note(note, note.author)
          noteable = note.noteable

          noteable.touch if event.commented? && noteable.respond_to?(:touch)
          note.create_cross_references!
          execute_hooks(note)
        end
      end

      note
    end

    def hook_data(note)
      Gitlab::NoteDataBuilder.build(note, current_user)
    end

    def execute_hooks(note)
      note_data = hook_data(note)
      note.project.execute_hooks(note_data, :note_hooks)
      note.project.execute_services(note_data, :note_hooks)
    end
  end
end
