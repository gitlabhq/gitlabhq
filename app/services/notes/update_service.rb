# frozen_string_literal: true

module Notes
  class UpdateService < BaseService
    def execute(note)
      return note unless note.editable? && params.present?

      old_mentioned_users = note.mentioned_users(current_user).to_a

      note.assign_attributes(params)

      return note unless note.valid?

      track_note_edit_usage_for_issues(note) if note.for_issue?
      track_note_edit_usage_for_merge_requests(note) if note.for_merge_request?

      only_commands = false

      quick_actions_service = QuickActionsService.new(project, current_user)
      if quick_actions_service.supported?(note)
        content, update_params, message, command_names = quick_actions_service.execute(note, {})

        only_commands = content.empty?

        note.note = content
        status = ::Notes::QuickActionsStatus.new(
          command_names: command_names, commands_only: only_commands)
        status.add_message(message)
        note.quick_actions_status = status
      end

      update_note(note, only_commands)
      note.save

      unless only_commands || note.for_personal_snippet?
        note.create_new_cross_references!(current_user)

        update_todos(note, old_mentioned_users)

        update_suggestions(note)

        execute_note_webhook(note)
      end

      if quick_actions_service.commands_executed_count.to_i > 0
        if update_params.present?
          quick_actions_service.apply_updates(update_params, note)
          note.commands_changes = update_params
        end

        if only_commands
          delete_note(note, message)
        else
          note.save
        end
      end

      note
    end

    private

    def update_note(note, only_commands)
      return unless note.note_changed?

      note.assign_attributes(last_edited_at: Time.current, updated_by: current_user)
      note.check_for_spam(action: :update, user: current_user) unless only_commands
    end

    def delete_note(note, message)
      note.quick_actions_status.add_error(_('Commands did not apply')) if message.blank?

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

    def track_note_edit_usage_for_issues(note)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_comment_edited_action(
        author: note.author,
        project: project
      )
    end

    def execute_note_webhook(note)
      return unless note.project && note.previous_changes.include?('note')

      note_data = Gitlab::DataBuilder::Note.build(note, note.author, :update)
      is_confidential = note.confidential?(include_noteable: true)
      hooks_scope = is_confidential ? :confidential_note_hooks : :note_hooks

      note.project.execute_hooks(note_data, hooks_scope)
    end

    def track_note_edit_usage_for_merge_requests(note)
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_edit_comment_action(note: note)
    end
  end
end

Notes::UpdateService.prepend_mod_with('Notes::UpdateService')
