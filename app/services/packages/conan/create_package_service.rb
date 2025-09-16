# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageService < ::Packages::CreatePackageService
      def execute
        if package_protected?(package_name: params[:package_name], package_type: :conan)
          return ERROR_RESPONSE_PACKAGE_PROTECTED
        end

        created_package = create_package!(
          ::Packages::Conan::Package,
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
    end
  end
end
