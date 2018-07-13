module Epics
  class UpdateService < Epics::BaseService
    def execute(epic)
      # start_date and end_date columns are no longer writable by users because those
      # are composite fields managed by the system.
      params.except!(:start_date, :end_date)

      update(epic)

      epic
    end

    def handle_changes(epic, options)
      old_associations = options.fetch(:old_associations, {})
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_labels = old_associations.fetch(:labels, [])

      if has_changes?(epic, old_labels: old_labels)
        todo_service.mark_pending_todos_as_done(epic, current_user)
      end

      todo_service.update_epic(epic, current_user, old_mentioned_users)
    end
  end
end
