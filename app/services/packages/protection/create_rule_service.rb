# frozen_string_literal: true

module Packages
  module Protection
    class CreateRuleService < BaseProjectService
      ALLOWED_ATTRIBUTES = %i[
        package_name_pattern
        package_type
        minimum_access_level_for_delete
        minimum_access_level_for_push
      ].freeze

      def execute
        unless can?(current_user, :admin_package, project)
          error_message = _('Unauthorized to create a package protection rule')
          return service_response_error(message: error_message)
        end

        creation_params = creation_params_with_defaults(params.slice(*ALLOWED_ATTRIBUTES))
        package_protection_rule = project.package_protection_rules.create(creation_params)

        unless package_protection_rule.persisted?
          return service_response_error(message: package_protection_rule.errors.full_messages)
        end

        ServiceResponse.success(payload: { package_protection_rule: package_protection_rule })
      rescue StandardError => e
        service_response_error(message: e.message)
      end

      private

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { package_protection_rule: nil }
        )
      end

      def creation_params_with_defaults(params)
        params.merge(
          pattern: params[:package_name_pattern],
          # These 2 fields are currently fixed values for all package protection rules
          pattern_type: Packages::Protection::Rule.pattern_types[:wildcard],
          target_field: Packages::Protection::Rule.target_fields[:package_name]
        )
      end
    end
  end
end
