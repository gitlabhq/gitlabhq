# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class PrepareUpdateService
      include Gitlab::Utils::StrongMemoize

      SUPPORTED_PARAMS = %i[status status_change_reason].freeze

      InvalidParamError = Class.new(StandardError)

      def initialize(issuable, current_user, params)
        @issuable = issuable
        @current_user = current_user
        @params = params.dup || {}
        @project = issuable.project
      end

      def execute
        return availability_error unless available?

        filter_unsupported_params
        filter_attributes
        filter_redundant_params

        ServiceResponse.success(payload: { escalation_status: params })
      rescue InvalidParamError
        invalid_param_error
      end

      private

      attr_reader :issuable, :current_user, :params, :project

      def available?
        issuable.supports_escalation? &&
          user_has_permissions? &&
          escalation_status.present?
      end

      def user_has_permissions?
        current_user&.can?(:update_escalation_status, issuable)
      end

      def escalation_status
        strong_memoize(:escalation_status) do
          issuable.escalation_status
        end
      end

      def filter_unsupported_params
        params.slice!(*supported_params)
      end

      def supported_params
        SUPPORTED_PARAMS
      end

      def filter_attributes
        filter_status
      end

      def filter_status
        status = params.delete(:status)
        return unless status

        status_event = escalation_status.status_event_for(status)
        raise InvalidParamError unless status_event

        params[:status_event] = status_event
      end

      def filter_redundant_params
        params.delete_if do |key, value|
          current_params.key?(key) && current_params[key] == value
        end
      end

      def current_params
        strong_memoize(:current_params) do
          {
            status_event: escalation_status.status_event_for(escalation_status.status_name)
          }
        end
      end

      def availability_error
        ServiceResponse.error(message: 'Escalation status updates are not available for this issue, user, or project.')
      end

      def invalid_param_error
        ServiceResponse.error(message: 'Invalid value was provided for a parameter.')
      end
    end
  end
end

::IncidentManagement::IssuableEscalationStatuses::PrepareUpdateService.prepend_mod
