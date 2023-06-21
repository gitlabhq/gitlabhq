# frozen_string_literal: true

module Admin
  module PlanLimits
    class UpdateService < ::BaseService
      def initialize(params = {}, current_user:, plan:)
        @current_user = current_user
        @params = params
        @plan = plan
        @plan_limits = plan.actual_limits
      end

      def execute
        return error(_('Access denied'), :forbidden) unless can_update?

        add_history_to_params!

        if plan_limits.update(parsed_params)
          success
        else
          error(plan_limits.errors.full_messages, :bad_request)
        end
      end

      private

      attr_accessor :current_user, :params, :plan, :plan_limits

      def can_update?
        current_user.can_admin_all_resources?
      end

      def add_history_to_params!
        formatted_limits_history = plan_limits.format_limits_history(current_user, parsed_params)
        parsed_params.merge!(limits_history: formatted_limits_history) unless formatted_limits_history.empty?
      end

      # Overridden in EE
      def parsed_params
        params
      end
    end
  end
end

Admin::PlanLimits::UpdateService.prepend_mod_with('Admin::PlanLimits::UpdateService')
