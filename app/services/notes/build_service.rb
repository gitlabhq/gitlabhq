module Notes
  class BuildService < ::BaseService
    def execute
      in_reply_to_discussion_id = params.delete(:in_reply_to_discussion_id)

      if project && in_reply_to_discussion_id.present?
        discussion = project.notes.find_discussion(in_reply_to_discussion_id)

        unless discussion
          note = Note.new
          note.errors.add(:base, 'Discussion to reply to cannot be found')
          return note
        end

        params.merge!(discussion.reply_attributes)
      end

      note = Note.new(params)
      note.project = project
      note.author = current_user

      note
    end
  end
end
