# frozen_string_literal: true

module Groups # rubocop:disable Gitlab/BoundedContexts -- existing top-level module
  class MarkForDeletionService < BaseService
    def execute
      return error(_('You are not authorized to perform this action')) unless can?(current_user, :remove_group, group)
      return error(_('Group has been already marked for deletion')) if group.marked_for_deletion_on.present?

      result = create_deletion_schedule
      if result[:status] == :success
        log_event
        send_group_deletion_notification
      end

      result
    end

    private

    def send_group_deletion_notification
      return unless group.adjourned_deletion?

      ::NotificationService.new.group_scheduled_for_deletion(group)
    end

    def create_deletion_schedule
      deletion_schedule = group.build_deletion_schedule(deletion_schedule_params)

      if deletion_schedule.save
        success
      else
        errors = deletion_schedule.errors.full_messages.to_sentence

        error(errors)
      end
    end

    def deletion_schedule_params
      { marked_for_deletion_on: Time.current.utc, deleting_user: current_user }
    end

    def log_event
      log_info("User #{current_user.id} marked group #{group.full_path} for deletion")
    end
  end
end

Groups::MarkForDeletionService.prepend_mod
