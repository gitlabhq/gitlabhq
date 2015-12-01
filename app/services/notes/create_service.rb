module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if award_emoji_note?
        note.is_award = true
        note.note = emoji_name
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

    private

    def award_emoji_note?
      # We support award-emojis only in issue discussion
      issue_comment? && contains_emoji_only?
    end

    def contains_emoji_only?
      params[:note] =~ /\A:[-_+[:alnum:]]*:\s?\z/
    end

    def issue_comment?
      params[:noteable_type] == 'Issue'
    end

    def emoji_name
      params[:note].match(/\A:([-_+[:alnum:]]*):\s?/)[1]
    end
  end
end
