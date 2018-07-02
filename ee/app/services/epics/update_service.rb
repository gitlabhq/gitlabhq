module Epics
  class UpdateService < Epics::BaseService
    def execute(epic)
      update(epic)

      epic
    end

    def handle_changes(epic, options)
      old_associations = options.fetch(:old_associations, {})
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])

      todo_service.update_epic(epic, current_user, old_mentioned_users)
    end
  end
end
