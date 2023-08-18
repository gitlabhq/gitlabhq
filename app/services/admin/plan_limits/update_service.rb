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

        plan_limits.assign_attributes(parsed_params)

        validate_storage_limits

        return error(plan_limits.errors.full_messages, :bad_request) if plan_limits.errors.any?

        if plan_limits.update(parsed_params)
          success
        else
          error(plan_limits.errors.full_messages, :bad_request)
        end
      end

      private

      attr_accessor :current_user, :params, :plan, :plan_limits

      delegate :notification_limit, :storage_size_limit, :enforcement_limit, to: :plan_limits

      def can_update?
        current_user.can_admin_all_resources?
      end

      def add_history_to_params!
        formatted_limits_history = plan_limits.format_limits_history(current_user, parsed_params)
        parsed_params.merge!(limits_history: formatted_limits_history) unless formatted_limits_history.empty?
      end

      def validate_storage_limits
        validate_notification_limit
        validate_enforcement_limit
        validate_storage_size_limit
      end

      def validate_notification_limit
        return unless parsed_params.include?(:notification_limit)
        return if notification_limit >= storage_size_limit && notification_limit <= enforcement_limit

        plan_limits.errors.add(:notification_limit, "must be greater than or equal to " \
                                                    "storage_size_limit (Dashboard limit): #{storage_size_limit} " \
                                                    "and less than or equal to enforcement_limit: #{enforcement_limit}")
      end

      def validate_enforcement_limit
        return unless parsed_params.include?(:enforcement_limit)
        return if enforcement_limit >= storage_size_limit && enforcement_limit >= notification_limit

        plan_limits.errors.add(:enforcement_limit, "must be greater than or equal to " \
                                                   "storage_size_limit (Dashboard limit): #{storage_size_limit} and " \
                                                   "greater than or equal to notification_limit: #{notification_limit}")
      end

      def validate_storage_size_limit
        return unless parsed_params.include?(:storage_size_limit)
        return if storage_size_limit <= enforcement_limit && storage_size_limit <= notification_limit

        plan_limits.errors.add(:storage_size_limit, "(Dashboard limit) must be less than or equal to " \
                                                    "enforcement_limit: #{enforcement_limit} " \
                                                    "and notification_limit: #{notification_limit}")
      end

      # Overridden in EE
      def parsed_params
        params
      end
    end
  end
end

Admin::PlanLimits::UpdateService.prepend_mod_with('Admin::PlanLimits::UpdateService')
