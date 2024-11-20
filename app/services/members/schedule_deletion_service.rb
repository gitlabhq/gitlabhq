# frozen_string_literal: true

module Members
  class ScheduleDeletionService
    include BaseServiceUtility

    def initialize(root_namespace, user_id, scheduled_by)
      @root_namespace = root_namespace
      @user_id = user_id
      @scheduled_by = scheduled_by
    end

    def execute
      return error('Must be a root namespace') unless root_namespace.root?
      return error('User not authorized') unless can?(scheduled_by, :admin_group_member, root_namespace)

      schedule_deletion
    end

    private

    attr_reader :root_namespace, :user_id, :scheduled_by

    def schedule_deletion
      schedule = Members::DeletionSchedule.new(
        namespace: root_namespace,
        user_id: user_id,
        scheduled_by: scheduled_by
      )

      return error(schedule.errors.full_messages) unless schedule.save

      success(deletion_schedule: schedule)
    end
  end
end
