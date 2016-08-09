module Notes
  class SlashCommandsService < BaseService

    UPDATE_SERVICES = {
      'Issue' => Issues::UpdateService,
      'MergeRequest' => MergeRequests::UpdateService
    }

    def execute(note)
      noteable_update_service = UPDATE_SERVICES[note.noteable_type]
      return false unless noteable_update_service
      return false unless can?(current_user, :"update_#{note.noteable_type.underscore}", note.noteable)

      commands = SlashCommands::InterpretService.new(project, current_user).
        execute(note.note, note.noteable)

      if commands.any?
        noteable_update_service.new(project, current_user, commands).execute(note.noteable)
      end
    end
  end
end
