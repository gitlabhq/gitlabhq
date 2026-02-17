# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class DeactivateSchedulesWorker
      include Gitlab::EventStore::Subscriber

      feature_category :continuous_integration
      data_consistency :delayed
      idempotent!

      def handle_event(event)
        user_ids = event.data[:user_ids]
        return if user_ids.blank?

        # This is looking at AuthorizationsRemovedEvent & AuthorizationsAddedEvent
        # There is no ChangedEvent, AuthorizationsAddedEvent is sent instead
        project_ids = event.data[:project_ids].presence || [event.data[:project_id]].compact
        return if project_ids.blank?

        deactivate_invalid_schedules(project_ids, user_ids)
      end

      private

      def deactivate_invalid_schedules(project_ids, user_ids)
        schedules = Ci::PipelineSchedule
          .active
          .owned_by(user_ids)
          .for_project(project_ids)
          .includes(:project, :owner) # rubocop:disable CodeReuse/ActiveRecord -- Preloading to prevent N+1

        schedules.find_each do |schedule|
          next if schedule.owner.can?(:create_pipeline, schedule.project)

          NotificationService.new.pipeline_schedule_owner_unavailable(schedule)
          schedule.deactivate!
        end
      end
    end
  end
end
