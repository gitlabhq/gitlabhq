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
        notify_and_disable_schedules(unavailable_schedules)
      else
        source.all_projects.find_in_batches do |batch|
          project_ids = batch.pluck(:id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit-- find_in_batches limit 1000
          unavailable_schedules = Ci::PipelineSchedule.active
                                                      .owned_by(user_id)
                                                      .for_project(project_ids)
          notify_and_disable_schedules(unavailable_schedules)
        end
      end
    end

    def notify_and_disable_all_pipeline_schedules_for_user(user_id)
      schedules = Ci::PipelineSchedule.active.owned_by(user_id)
      notify_and_disable_schedules(schedules)
    end

    private

    def notify_and_disable_schedules(schedules)
      schedules.find_each do |schedule|
        notification_service.pipeline_schedule_owner_unavailable(schedule)
      end

      schedules.each_batch do |batch|
        batch.update_all(active: false)
      end
    end
  end
end
