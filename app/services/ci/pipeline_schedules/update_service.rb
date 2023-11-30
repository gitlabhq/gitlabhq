# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class UpdateService < BaseSaveService
      AUTHORIZE = :update_pipeline_schedule

      def initialize(schedule, user, params)
        @schedule = schedule
        @user = user
        @project = schedule.project
        @params = params
      end

      def execute
        return forbidden_to_save unless allowed_to_save?

        super
      end

      private

      def authorize_message
        _('The current user is not authorized to update the pipeline schedule')
      end
      strong_memoize_attr :authorize_message
    end
  end
end
