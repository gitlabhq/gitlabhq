module Epics
  class UpdateService < Epics::BaseService
    def execute(epic)
      update(epic)

      # TODO: old_mentioned_users
      # TODO: move to handle_changes method
      todo_service.update_epic(epic, current_user, [])

      epic
    end
  end
end
