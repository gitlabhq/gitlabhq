module Notes
  class SlashCommandsService < BaseService
    UPDATE_SERVICES = {
      'Issue' => Issues::UpdateService,
      'MergeRequest' => MergeRequests::UpdateService
    }

    def supported?(note)
      noteable_update_service(note) &&
        can?(current_user, :"update_#{note.noteable_type.underscore}", note.noteable)
    end

    def extract_commands(note)
      return [note.note, {}] unless supported?(note)

      SlashCommands::InterpretService.new(project, current_user).
        execute(note.note, note.noteable)
    end

    def execute(command_params, note)
      return if command_params.empty?
      return unless supported?(note)

      noteable_update_service(note).new(project, current_user, command_params).execute(note.noteable)
    end

    private

    def noteable_update_service(note)
      UPDATE_SERVICES[note.noteable_type]
    end
  end
end
