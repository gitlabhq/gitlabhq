# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class UpdateService
      def initialize(schedule, user, params)
        @schedule = schedule
        @user = user
        @params = params
      end

      def execute
        return forbidden unless allowed?

        if schedule.update(@params)
          ServiceResponse.success(payload: schedule)
        else
          ServiceResponse.error(message: schedule.errors.full_messages)
        end
      end

      private

      attr_reader :schedule, :user

      def allowed?
        user.can?(:update_pipeline_schedule, schedule)
      end

      def forbidden
        ServiceResponse.error(
          message: _('The current user is not authorized to update the pipeline schedule'),
          reason: :forbidden
        )
      end
    end
  end
end
