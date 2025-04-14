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

        prepare_inputs_for_update

        super
      end

      private

      def authorize_message
        _('The current user is not authorized to update the pipeline schedule')
      end
      strong_memoize_attr :authorize_message

      def prepare_inputs_for_update
        return unless params[:inputs_attributes].present?

        inputs_names = params[:inputs_attributes].pluck(:name) # rubocop:disable Database/AvoidUsingPluckWithoutLimit, CodeReuse/ActiveRecord -- This is Array#pluck, not the ActiveRecord #pluck method
        inputs_identifiers = ::Ci::PipelineScheduleInput.pluck_identifiers(schedule.id, inputs_names)
        inputs_names_to_ids = inputs_identifiers.to_h { |id, name| [name, id] }

        params[:inputs_attributes].each do |input|
          input[:id] = inputs_names_to_ids[input[:name]]
          input[:_destroy] = input.delete(:destroy)
        end
      end
    end
  end
end
