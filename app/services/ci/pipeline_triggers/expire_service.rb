# frozen_string_literal: true

module Ci
  module PipelineTriggers
    class ExpireService
      include Gitlab::Allowable

      def initialize(user:, trigger:)
        @current_user = user
        @trigger = trigger
      end

      def execute
        unless can?(current_user, :manage_trigger, trigger)
          return ServiceResponse.error(
            message: _('The current user is not authorized to manage the pipeline trigger token'),
            reason: :forbidden
          ).freeze
        end

        if trigger.update(expires_at: Time.current)
          ServiceResponse.success
        else
          ServiceResponse.error(message: trigger.errors.full_messages.to_sentence)
        end
      end

      private

      attr_reader :current_user, :trigger
    end
  end
end
