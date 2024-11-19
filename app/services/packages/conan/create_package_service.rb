# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageService < ::Packages::CreatePackageService
      ERROR_RESPONSE_PACKAGE_PROTECTED =
        ServiceResponse.error(message: 'Package protected.', reason: :package_protected)

      def execute
        return ERROR_RESPONSE_PACKAGE_PROTECTED if current_package_protected?

        created_package = create_package!(:conan,
          name: params[:package_name],
          version: params[:package_version],
          conan_metadatum_attributes: {
            package_username: params[:package_username],
            package_channel: params[:package_channel]
          }
        )

        ServiceResponse.success(payload: { package: created_package })
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message, reason: :record_invalid)
      rescue ArgumentError => e
        ServiceResponse.error(message: e.message, reason: :invalid_parameter)
      end

      private

      def current_package_protected?
        return false if Feature.disabled?(:packages_protected_packages_conan, project)

        service_response =
          Packages::Protection::CheckRuleExistenceService.new(
            project: project,
            current_user: current_user,
            params: { package_name: params[:package_name], package_type: :conan }
          ).execute

        raise ArgumentError, service_response.message if service_response.error?

        service_response[:protection_rule_exists?]
      end
    end
  end
end
