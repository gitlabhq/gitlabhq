module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      return unless valid_project?(note)

      if note.save
        notification_service.new_note(note)

        # Skip system notes, like status changes and cross-references and awards
        unless note.system || note.is_award
          event_service.leave_note(note, note.author)
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

    private

    def valid_project?(note)
      return false unless project
      return true if note.for_commit?

      note.noteable.try(:project) == project
    end
  end
end
