module Notes
  class BuildService < ::BaseService
    DiscussionNotFound = Class.new(StandardError)

    def execute
      begin
        reply_attributes = discussion_reply_attributes
      rescue DiscussionNotFound
        note = Note.new
        note.errors.add(:base, 'Discussion to reply to cannot be found')
        return note
      end

      params.merge!(reply_attributes) if reply_attributes

      note = Note.new(params)
      note.project = project
      note.author = current_user

      note
    end

    private

    def discussion_reply_attributes
      new_discussion = params.delete(:new_discussion)
      in_reply_to_discussion_id = params.delete(:in_reply_to_discussion_id)

      return if in_reply_to_discussion_id.blank?

      discussion = find_discussion(in_reply_to_discussion_id)
      raise DiscussionNotFound unless discussion

      if new_discussion.present? && discussion.can_become_discussion?
        discussion = discussion.becomes_discussion!
      end

      discussion.reply_attributes
    end

    def find_discussion(discussion_id)
      if project
        project.notes.find_discussion(discussion_id)
      else
        # only PersonalSnippets can have discussions without project association
        discussion = Note.find_discussion(discussion_id)
        noteable = discussion.noteable

        return nil unless noteable.is_a?(PersonalSnippet) && can?(current_user, :comment_personal_snippet, noteable)

        discussion
      end
    end
  end
end
