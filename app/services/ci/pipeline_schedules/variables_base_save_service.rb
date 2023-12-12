# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class VariablesBaseSaveService
      include Gitlab::Utils::StrongMemoize

      def execute
        variable.assign_attributes(params)

        return forbidden_to_update_pipeline_schedule unless allowed_to_update_pipeline_schedule?
        return forbidden_to_save_variables unless allowed_to_save_variables?

        if variable.save
          ServiceResponse.success(payload: variable)
        else
          ServiceResponse.error(payload: variable, message: variable.errors.full_messages)
        end
      end

      private

      attr_reader :project, :user, :params, :variable, :pipeline_schedule

      def allowed_to_update_pipeline_schedule?
        user.can?(:update_pipeline_schedule, pipeline_schedule)
      end

      def forbidden_to_update_pipeline_schedule
        # We add the error to the base object too
        # because model errors are used in the API responses and the `form_errors` helper.
        pipeline_schedule.errors.add(:base, authorize_message)

        ServiceResponse.error(payload: pipeline_schedule, message: [authorize_message], reason: :forbidden)
      end

      def allowed_to_save_variables?
        user.can?(:set_pipeline_variables, project)
      end

      def forbidden_to_save_variables
        message = _('The current user is not authorized to set pipeline schedule variables')

        # We add the error to the base object too
        # because model errors are used in the API responses and the `form_errors` helper.
        pipeline_schedule.errors.add(:base, message)

        ServiceResponse.error(payload: pipeline_schedule, message: [message], reason: :forbidden)
      end
    end
  end
end
