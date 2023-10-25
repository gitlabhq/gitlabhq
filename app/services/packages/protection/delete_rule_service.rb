# frozen_string_literal: true

module Packages
  module Protection
    class DeleteRuleService
      include Gitlab::Allowable

      def initialize(package_protection_rule, current_user:)
        if package_protection_rule.blank? || current_user.blank?
          raise ArgumentError,
            'package_protection_rule and current_user must be set'
        end

        @package_protection_rule = package_protection_rule
        @current_user = current_user
      end

      def execute
        unless can?(current_user, :admin_package, package_protection_rule.project)
          error_message = _('Unauthorized to delete a package protection rule')
          return service_response_error(message: error_message)
        end

        deleted_package_protection_rule = package_protection_rule.destroy!

        ServiceResponse.success(payload: { package_protection_rule: deleted_package_protection_rule })
      rescue StandardError => e
        service_response_error(message: e.message)
      end

      private

      attr_reader :package_protection_rule, :current_user

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { package_protection_rule: nil }
        )
      end
    end
  end
end
