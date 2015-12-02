module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if contains_emoji_only?(params[:note])
        note.is_award = true
        note.note = emoji_name(params[:note])
      end

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

    def contains_emoji_only?(note)
      note =~ /\A:[-_+[:alnum:]]*:\s?\z/
    end

    def emoji_name(note)
      note.match(/\A:([-_+[:alnum:]]*):\s?/)[1]
    end
  end
end
