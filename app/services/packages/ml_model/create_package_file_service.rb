# frozen_string_literal: true

module Packages
  module MlModel
    class CreatePackageFileService < BaseService
      def execute
        ::Packages::Package.transaction do
          create_package_file(find_or_create_package)
        end
      end

      private

      def find_or_create_package
        package_params = {
          name: params[:package_name],
          version: params[:package_version],
          build: params[:build],
          status: params[:status]
        }

        package = ::Packages::MlModel::FindOrCreatePackageService
                    .new(project, current_user, package_params)
                    .execute

        package.update_column(:status, params[:status]) if params[:status] && params[:status] != package.status

        package.create_build_infos!(params[:build])

        package
      end

      def create_package_file(package)
        file_params = {
          file: params[:file],
          size: params[:file].size,
          file_sha256: params[:file].sha256,
          file_name: params[:file_name],
          build: params[:build]
        }

        ::Packages::CreatePackageFileService.new(package, file_params).execute
      end
    end
  end
end
