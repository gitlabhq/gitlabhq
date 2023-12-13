# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class VariablesUpdateService < VariablesBaseSaveService
      AUTHORIZE = :update_pipeline_schedule

      def initialize(pipeline_schedule_variable, user, params)
        @variable = pipeline_schedule_variable
        @user = user
        @pipeline_schedule = pipeline_schedule_variable.pipeline_schedule
        @project = pipeline_schedule.project
        @params = params
      end

      private

      def authorize_message
        _('The current user is not authorized to update the pipeline schedule variables')
      end
      strong_memoize_attr :authorize_message
    end
  end
end
