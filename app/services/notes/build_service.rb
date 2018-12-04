# frozen_string_literal: true

module Notes
  class BuildService < ::BaseService
    def execute
      should_resolve = false
      in_reply_to_discussion_id = params.delete(:in_reply_to_discussion_id)

      if in_reply_to_discussion_id.present?
        discussion = find_discussion(in_reply_to_discussion_id)

        unless discussion
          note = Note.new
          note.errors.add(:base, 'Discussion to reply to cannot be found')
          return note
        end

        params.merge!(discussion.reply_attributes)
        should_resolve = discussion.resolved?
      end

      note = Note.new(params)
      note.project = project
      note.author = current_user

      if should_resolve
        note.resolve_without_save(current_user)
      end

      note
    end

    def find_discussion(discussion_id)
      if project
        project.notes.find_discussion(discussion_id)
      else
        discussion = Note.find_discussion(discussion_id)
        noteable = discussion.noteable

        return nil unless noteable_without_project?(noteable)

        discussion
      end
    end

    def noteable_without_project?(noteable)
      return true if noteable.is_a?(PersonalSnippet) && can?(current_user, :comment_personal_snippet, noteable)

      false
    end
  end
end
