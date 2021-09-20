# frozen_string_literal: true

module Projects
  class MoveNotificationSettingsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      Project.transaction do
        move_notification_settings
        remove_remaining_notification_settings if remove_remaining_elements

        success
      end
    end

    private

    def move_notification_settings
      non_existent_notifications.update_all(source_id: @project.id)
    end

    # Remove remaining notification settings from source_project
    def remove_remaining_notification_settings
      source_project.notification_settings.destroy_all # rubocop: disable Cop/DestroyAll
    end

    # Get users of current notification_settings
    def users_in_target_project
      @project.notification_settings.select(:user_id)
    end

    # Look for notification_settings in source_project that are not in the target project
    # rubocop: disable CodeReuse/ActiveRecord
    def non_existent_notifications
      source_project.notification_settings
        .select(:id)
        .where.not(user_id: users_in_target_project)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
