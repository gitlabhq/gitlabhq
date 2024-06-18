# frozen_string_literal: true

module Packages
  module Protection
    class UpdateRuleService
      include Gitlab::Allowable

      ALLOWED_ATTRIBUTES = %i[
        package_name_pattern
        package_type
        minimum_access_level_for_push
      ].freeze

      def initialize(package_protection_rule, current_user:, params:)
        if package_protection_rule.blank? || current_user.blank?
          raise ArgumentError,
            'package_protection_rule and current_user must be set'
        end

        @package_protection_rule = package_protection_rule
        @current_user = current_user
        @params = params || {}
      end

      def execute
        unless can?(current_user, :admin_package, package_protection_rule.project)
          error_message = _('Unauthorized to update a package protection rule')
          return service_response_error(message: error_message)
        end

        package_protection_rule.update(params.slice(*ALLOWED_ATTRIBUTES))

        if package_protection_rule.errors.present?
          return service_response_error(message: package_protection_rule.errors.full_messages)
        end

        ServiceResponse.success(payload: { package_protection_rule: package_protection_rule })
      rescue StandardError => e
        service_response_error(message: e.message)
      end

      private

      attr_reader :package_protection_rule, :current_user, :params

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { package_protection_rule: nil }
        )
      end
    end
  end
end
