# frozen_string_literal: true

module Packages
  module Generic
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
          build: params[:build]
        }

        package = ::Packages::Generic::FindOrCreatePackageService
          .new(project, current_user, package_params)
          .execute

        package.build_infos.safe_find_or_create_by!(pipeline: params[:build].pipeline) if params[:build].present?
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
