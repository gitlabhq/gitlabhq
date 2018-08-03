module Epics
  class UpdateService < Epics::BaseService
    EPIC_DATE_FIELDS = %I[
      start_date_fixed
      start_date_is_fixed
      due_date_fixed
      due_date_is_fixed
    ].freeze

    def execute(epic)
      # start_date and end_date columns are no longer writable by users because those
      # are composite fields managed by the system.
      params.except!(:start_date, :end_date)

      update(epic)

      epic.update_start_and_due_dates if have_epic_dates_changed?(epic)

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

    private

    def have_epic_dates_changed?(epic)
      (epic.previous_changes.keys.map(&:to_sym) & EPIC_DATE_FIELDS).present?
    end
  end
end
