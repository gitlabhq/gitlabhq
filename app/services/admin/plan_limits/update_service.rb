# frozen_string_literal: true

module Admin
  module PlanLimits
    class UpdateService < ::BaseService
      def initialize(params = {}, current_user:, plan:)
        @current_user = current_user
        @params = params
        @plan = plan
      end

      def execute
        return error(_('Access denied'), :forbidden) unless can_update?

        if plan.actual_limits.update(parsed_params)
          success
        else
          error(plan.actual_limits.errors.full_messages, :bad_request)
        end
      end

      private

      attr_accessor :current_user, :params, :plan

      def can_update?
        current_user.can_admin_all_resources?
      end

      # Overridden in EE
      def parsed_params
        params
      end
    end
  end
end

Admin::PlanLimits::UpdateService.prepend_mod_with('Admin::PlanLimits::UpdateService')
