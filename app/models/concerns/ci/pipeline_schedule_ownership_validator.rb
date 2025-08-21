# frozen_string_literal: true

module Ci
  module PipelineScheduleOwnershipValidator
    extend ActiveSupport::Concern

    def pipeline_schedule_ownership_revoked?
      return false unless saved_change_to_access_level?

      old_access, new_access = saved_change_to_access_level

      old_access&.>=(Gitlab::Access::DEVELOPER) && new_access&.<(Gitlab::Access::DEVELOPER)
    end

    def notify_unavailable_owned_pipeline_schedules(user_id, source)
      if source.is_a?(Project)
        unavailable_schedules = Ci::PipelineSchedule.active
                                                    .owned_by(user_id)
                                                    .for_project(source.id)
        process_schedules(unavailable_schedules)
      else
        source.all_projects.find_in_batches do |batch|
          project_ids = batch.pluck(:id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit-- find_in_batches limit 1000
          unavailable_schedules = Ci::PipelineSchedule.active
                                                      .owned_by(user_id)
                                                      .for_project(project_ids)

          process_schedules(unavailable_schedules)
        end
      end
    end

    private

    def process_schedules(schedules)
      schedules.each do |schedule|
        notification_service.pipeline_schedule_owner_unavailable(schedule)
        schedule.deactivate!
      end
    end
  end
end
