# frozen_string_literal: true

module Members
  class ScheduleDeletionService
    include BaseServiceUtility

    def initialize(root_namespace, user_id, scheduled_by, ip_address = nil)
      @root_namespace = root_namespace
      @user_id = user_id
      @scheduled_by = scheduled_by
      @ip_address = ip_address
    end

    def execute
      return error('Must be a root namespace') unless root_namespace.root?
      return error('User not authorized') unless can?(scheduled_by, :admin_group_member, root_namespace)

      schedule_deletion
    end

    private

    attr_reader :root_namespace, :user_id, :scheduled_by, :ip_address

    def schedule_deletion
      schedule = Members::DeletionSchedule.new(
        namespace: root_namespace,
        user_id: user_id,
        scheduled_by: scheduled_by,
        ip_address: ip_address
      )

      return error(schedule.errors.full_messages) unless schedule.save

      success(deletion_schedule: schedule)
    end
  end
end
