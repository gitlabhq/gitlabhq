module Notes
  class CreateService < BaseService
    def execute
      note = project.notes.new(params)
      note.author = current_user
      note.system = false

      if note.award_emoji?
        noteable = note.noteable
        todo_service.new_award_emoji(noteable, current_user)
        return noteable.create_award_emoji(note.award_emoji_name, current_user)
      end

      # We execute commands (extracted from `params[:note]`) on the noteable
      # **before** we save the note because if the note consists of commands
      # only, there is no need be create a note!
      commands_executed = execute_slash_commands!(note)

      if note.save
        # Finish the harder work in the background
        NewNoteWorker.perform_in(2.seconds, note.id, params)
        todo_service.new_note(note, current_user)
      end

      if commands_executed && note.note.blank?
        note.errors.add(:commands_only, 'Your commands are being executed.')
      end

      note
    end

    private

    def execute_slash_commands!(note)
      noteable_update_service = noteable_update_service(note.noteable_type)
      return unless noteable_update_service

      command_params = SlashCommands::InterpretService.new(project, current_user).
        execute(note.note)

      commands = execute_or_filter_commands(command_params, note)

      if commands.any?
        noteable_update_service.new(project, current_user, commands).execute(note.noteable)
      end
    end

    def execute_or_filter_commands(commands, note)
      final_commands = commands.reduce({}) do |memo, (command_key, command_value)|
        if command_key != :due_date || note.noteable.respond_to?(:due_date)
          memo[command_key] = command_value
        end

        memo
      end

      final_commands
    end

    def noteable_update_service(noteable_type)
      case noteable_type
      when 'Issue'
        Issues::UpdateService
      when 'MergeRequest'
        MergeRequests::UpdateService
      else
        nil
      end
    end
  end
end
