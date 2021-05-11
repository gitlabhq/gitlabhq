# frozen_string_literal: true

module Notes
  class UpdateService < BaseService
    def execute(note)
      return note unless note.editable? && params.present?

      old_mentioned_users = note.mentioned_users(current_user).to_a

      note.assign_attributes(params)

      track_note_edit_usage_for_issues(note) if note.for_issue?
      track_note_edit_usage_for_merge_requests(note) if note.for_merge_request?

      only_commands = false

      quick_actions_service = QuickActionsService.new(project, current_user)
      if quick_actions_service.supported?(note)
        content, update_params, message = quick_actions_service.execute(note, {})

        only_commands = content.empty?

        note.note = content
      end

      if note.note_changed?
        note.assign_attributes(last_edited_at: Time.current, updated_by: current_user)
      end

      note.with_transaction_returning_status do
        update_confidentiality(note)
        note.save
      end

      unless only_commands || note.for_personal_snippet?
        note.create_new_cross_references!(current_user)

        update_todos(note, old_mentioned_users)

        update_suggestions(note)
      end

      if quick_actions_service.commands_executed_count.to_i > 0
        if update_params.present?
          quick_actions_service.apply_updates(update_params, note)
          note.commands_changes = update_params
        end

        if only_commands
          delete_note(note, message)
          note = nil
        else
          note.save
        end
      end

      note
    end

    private

    def delete_note(note, message)
      # We must add the error after we call #save because errors are reset
      # when #save is called
      note.errors.add(:commands_only, message.presence || _('Commands did not apply'))
      # Allow consumers to detect problems applying commands
      note.errors.add(:commands, _('Commands did not apply')) unless message.present?

      Notes::DestroyService.new(project, current_user).execute(note)
    end

    def update_suggestions(note)
      return unless note.supports_suggestion?

      Suggestion.transaction do
        note.suggestions.delete_all
        Suggestions::CreateService.new(note).execute
      end

      # We need to refresh the previous suggestions call cache
      # in order to get the new records.
      note.reset
    end

    def update_todos(note, old_mentioned_users)
      return unless note.previous_changes.include?('note')

      TodoService.new.update_note(note, current_user, old_mentioned_users)
    end

    # This method updates confidentiality of all discussion notes at once
    def update_confidentiality(note)
      return unless params.key?(:confidential)
      return unless note.is_a?(DiscussionNote) # we don't need to do bulk update for single notes
      return unless note.start_of_discussion? # don't update all notes if a response is being updated

      Note.id_in(note.discussion.notes.map(&:id)).update_all(confidential: params[:confidential])
    end

    def track_note_edit_usage_for_issues(note)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_comment_edited_action(author: note.author)
    end

    def track_note_edit_usage_for_merge_requests(note)
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_edit_comment_action(note: note)
    end
  end
end

Notes::UpdateService.prepend_mod_with('Notes::UpdateService')
