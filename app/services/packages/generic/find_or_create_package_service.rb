# frozen_string_literal: true

module Packages
  module Generic
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      def execute
        if package_protected?(package_name: params[:name], package_type: :generic)
          return ERROR_RESPONSE_PACKAGE_PROTECTED
        end

        package = find_or_create_package!(:generic)

        ServiceResponse.success(payload: { package: package })
      end
    end
  end
end
