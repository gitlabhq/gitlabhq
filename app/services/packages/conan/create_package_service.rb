# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageService < ::Packages::CreatePackageService
      ERROR_RESPONSE_PACKAGE_PROTECTED =
        ServiceResponse.error(message: 'Package protected.', reason: :package_protected)

      def execute
        return ERROR_RESPONSE_PACKAGE_PROTECTED if package_protected?

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

      def package_protected?
        return false if Feature.disabled?(:packages_protected_packages_conan, project)

        super(package_name: params[:package_name], package_type: :conan)
      end
    end
  end
end
