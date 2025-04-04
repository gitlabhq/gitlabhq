# frozen_string_literal: true

module Groups # rubocop:disable Gitlab/BoundedContexts -- existing top-level module
  class MarkForDeletionService < BaseService
    def execute(licensed: false)
      return error(_('You are not authorized to perform this action')) unless can?(current_user, :remove_group, group)
      return error(_('Group has been already marked for deletion')) if group.marked_for_deletion_on.present?
      return error(_('Cannot mark group for deletion: feature not supported')) unless licensed || feature_downtiered?

      result = create_deletion_schedule
      if result[:status] == :success
        log_event
        send_group_deletion_notification
      end

      result
    end

    private

    # overridden in EE
    def send_group_deletion_notification; end

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

    def feature_downtiered?
      Feature.enabled?(:downtier_delayed_deletion, :instance, type: :wip)
    end
  end
end

Groups::MarkForDeletionService.prepend_mod
