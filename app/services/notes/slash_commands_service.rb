module Notes
  class SlashCommandsService < BaseService
    UPDATE_SERVICES = {
      'Issue' => Issues::UpdateService,
      'MergeRequest' => MergeRequests::UpdateService
    }

    def extract_commands(note)
      @noteable_update_service = UPDATE_SERVICES[note.noteable_type]
      return [] unless @noteable_update_service
      return [] unless can?(current_user, :"update_#{note.noteable_type.underscore}", note.noteable)

      SlashCommands::InterpretService.new(project, current_user).
        execute(note.note, note.noteable)
    end

    def execute(command_params, note)
      return if command_params.empty?

      @noteable_update_service.new(project, current_user, command_params).
        execute(note.noteable)
    end
  end
end
