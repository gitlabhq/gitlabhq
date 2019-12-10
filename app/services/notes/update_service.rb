# frozen_string_literal: true

module Notes
  class UpdateService < BaseService
    def execute(note)
      return note unless note.editable?

      old_mentioned_users = note.mentioned_users(current_user).to_a

      note.assign_attributes(params.merge(updated_by: current_user))

      note.with_transaction_returning_status do
        note.save && note.store_mentions!
      end

      only_commands = false

      quick_actions_service = QuickActionsService.new(project, current_user)
      if quick_actions_service.supported?(note)
        content, update_params, message = quick_actions_service.execute(note, {})

        only_commands = content.empty?

        note.note = content
      end

      unless only_commands
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
  end
end
