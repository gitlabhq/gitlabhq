# frozen_string_literal: true

module Packages
  module Generic
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      def execute
        return ERROR_RESPONSE_PACKAGE_PROTECTED if package_protected?

        package = find_or_create_package!(:generic)

        ServiceResponse.success(payload: { package: package })
      end

      private

      def package_protected?
        return false if Feature.disabled?(:packages_protected_packages_generic, project)

        super(package_name: params[:name], package_type: :generic)
      end
    end
  end
end
