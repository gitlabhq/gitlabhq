# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageService < BaseService
      def execute
        project.packages.create!(
          name: params[:package_name],
          version: params[:package_version],
          package_type: :conan,
          conan_metadatum_attributes: {
            package_username: params[:package_username],
            package_channel: params[:package_channel]
          }
        )
      end
    end
  end
end
