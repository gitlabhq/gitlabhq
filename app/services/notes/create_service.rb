module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.save
        notification_service.new_note(note)
        update_participants(note)

        # Skip system notes, like status changes and cross-references.
        unless note.system
          event_service.leave_note(note, note.author)

          # Create a cross-reference note if this Note contains GFM that names an
          # issue, merge request, or commit.
          note.references.each do |mentioned|
            SystemNoteService.cross_reference(mentioned, note.noteable, note.author)
          end

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

    def update_participants(note)
      users = [note.author, note.mentioned_users].flatten
      noteable = note.noteable

      # Add users as participants only if they have access to project
      users.select! do |user|
        user.can?(:read_project, note.project)
      end

      users.each do |user|
        if Participant.where(user_id: user, target_id: noteable.id.to_s, target_type: noteable.class.name).blank?
          participant = Participant.new
          participant.target_id = noteable.id
          participant.target_type = noteable.class.name
          participant.user = user
          participant.save
        end
      end
    end
  end
end
