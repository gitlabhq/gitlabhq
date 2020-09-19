# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageService < ::Packages::CreatePackageService
      def execute
        create_package!(:conan,
          name: params[:package_name],
          version: params[:package_version],
          conan_metadatum_attributes: {
            package_username: params[:package_username],
            package_channel: params[:package_channel]
          }
        )
      end
    end
  end
end
