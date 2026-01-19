# frozen_string_literal: true

module Ci
  module PipelineScheduleOwnershipValidator
    extend ActiveSupport::Concern

    def notify_and_disable_all_pipeline_schedules_for_user(user_id)
      schedules = Ci::PipelineSchedule.active.owned_by(user_id)

      schedules.find_each do |schedule|
        notification_service.pipeline_schedule_owner_unavailable(schedule)
      end

      schedules.each_batch do |batch|
        batch.update_all(active: false)
      end
    end
  end
end
