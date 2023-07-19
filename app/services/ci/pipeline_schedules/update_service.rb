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

        schedule.assign_attributes(params)

        if schedule.save
          ServiceResponse.success(payload: schedule)
        else
          ServiceResponse.error(message: schedule.errors.full_messages)
        end
      end

      private

      attr_reader :schedule, :user, :params

      def allowed?
        user.can?(:update_pipeline_schedule, schedule)
      end

      def forbidden
        # We add the error to the base object too
        # because model errors are used in the API responses and the `form_errors` helper.
        schedule.errors.add(:base, forbidden_message)

        ServiceResponse.error(message: [forbidden_message], reason: :forbidden)
      end

      def forbidden_message
        _('The current user is not authorized to update the pipeline schedule')
      end
    end
  end
end
