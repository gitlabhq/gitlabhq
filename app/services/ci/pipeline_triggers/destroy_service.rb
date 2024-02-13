# frozen_string_literal: true

module Ci
  module PipelineTriggers
    class DestroyService
      include Gitlab::Allowable

      attr_reader :project, :current_user, :description, :trigger

      def initialize(user:, trigger:)
        @current_user = user
        @trigger = trigger
      end

      def execute
        unless can?(current_user, :manage_trigger, trigger)
          return ServiceResponse.error(
            message: _('The current user is not authorized to manage the pipeline trigger token'),
            reason: :forbidden
          )
        end

        trigger.destroy

        unless trigger.destroyed?
          return ServiceResponse.error(
            message: _('Attempted to destroy the pipeline trigger token but failed')
          )
        end

        ServiceResponse.success
      end
    end
  end
end
