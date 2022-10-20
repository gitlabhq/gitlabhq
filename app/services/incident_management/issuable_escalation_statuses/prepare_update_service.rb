# frozen_string_literal: true

module IncidentManagement
  module IssuableEscalationStatuses
    class PrepareUpdateService < ::BaseProjectService
      include Gitlab::Utils::StrongMemoize

      SUPPORTED_PARAMS = %i[status].freeze

      def initialize(issuable, current_user, params)
        @issuable = issuable
        @param_errors = []

        super(project: issuable.project, current_user: current_user, params: params)
      end

      def execute
        return availability_error unless available?

        filter_unsupported_params
        filter_attributes
        filter_redundant_params

        return invalid_param_error if param_errors.any?

        ServiceResponse.success(payload: { escalation_status: params })
      end

      private

      attr_reader :issuable, :param_errors

      def available?
        issuable.supports_escalation? && user_has_permissions?
      end

      def user_has_permissions?
        current_user&.can?(:update_escalation_status, issuable)
      end

      def escalation_status
        strong_memoize(:escalation_status) do
          issuable.escalation_status || BuildService.new(issuable).execute
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
        add_param_error(:status) && return unless status_event

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

      def add_param_error(param)
        param_errors << param
      end

      def availability_error
        ServiceResponse.error(message: 'Escalation status updates are not available for this issue, user, or project.')
      end

      def invalid_param_error
        ServiceResponse.error(message: "Invalid value was provided for parameters: #{param_errors.join(', ')}")
      end
    end
  end
end

::IncidentManagement::IssuableEscalationStatuses::PrepareUpdateService.prepend_mod
