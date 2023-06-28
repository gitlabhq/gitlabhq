# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class CreateService
      def initialize(project, user, params)
        @project = project
        @user = user
        @params = params

        @schedule = project.pipeline_schedules.new
      end

      def execute
        return forbidden unless allowed?

        schedule.assign_attributes(params.merge(owner: user))

        if schedule.save
          ServiceResponse.success(payload: schedule)
        else
          ServiceResponse.error(payload: schedule, message: schedule.errors.full_messages)
        end
      end

      private

      attr_reader :project, :user, :params, :schedule

      def allowed?
        user.can?(:create_pipeline_schedule, schedule)
      end

      def forbidden
        # We add the error to the base object too
        # because model errors are used in the API responses and the `form_errors` helper.
        schedule.errors.add(:base, forbidden_message)

        ServiceResponse.error(payload: schedule, message: [forbidden_message], reason: :forbidden)
      end

      def forbidden_message
        _('The current user is not authorized to create the pipeline schedule')
      end
    end
  end
end
