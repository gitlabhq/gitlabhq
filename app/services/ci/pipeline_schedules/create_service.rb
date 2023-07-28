# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class CreateService < BaseSaveService
      AUTHORIZE = :create_pipeline_schedule

      def initialize(project, user, params)
        @schedule = project.pipeline_schedules.new
        @user = user
        @project = project
        @params = params.merge(owner: user)
      end

      private

      def authorize_message
        _('The current user is not authorized to create the pipeline schedule')
      end
      strong_memoize_attr :authorize_message
    end
  end
end
