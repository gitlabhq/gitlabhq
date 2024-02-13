# frozen_string_literal: true

module Ci
  module PipelineTriggers
    class UpdateService
      include Gitlab::Allowable

      attr_reader :current_user, :description, :trigger

      def initialize(user:, trigger:, description:)
        @current_user = user
        @description = description
        @trigger = trigger
      end

      def execute
        unless can?(current_user, :admin_trigger, trigger)
          return ServiceResponse.error(
            message: _('The current user is not authorized to update the pipeline trigger token'),
            payload: { trigger: trigger },
            reason: :forbidden
          )
        end

        if trigger.update(**update_params)
          ServiceResponse.success(payload: { trigger: trigger })
        else
          ServiceResponse.error(
            message: _('Attempted to update the pipeline trigger token but failed'),
            payload: { trigger: trigger }
          )
        end
      end

      private

      def update_params
        { description: description }
      end
    end
  end
end
