module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.save
        notification_service.new_note(note)

        # Skip system notes, like status changes and cross-references.
        unless note.system
          event_service.leave_note(note, note.author)

          # Create a cross-reference note if this Note contains GFM that names an
          # issue, merge request, or commit.
          note.references.each do |mentioned|
            Note.create_cross_reference_note(mentioned, note.noteable, note.author, note.project)
          end
        end
      end

      note
    end
  end
end
