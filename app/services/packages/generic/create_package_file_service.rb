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
          build: params[:build],
          status: params[:status]
        }

        package = ::Packages::Generic::FindOrCreatePackageService
          .new(project, current_user, package_params)
          .execute

        unless Namespace::PackageSetting.duplicates_allowed?(package)
          raise ::Packages::DuplicatePackageError if target_file_is_duplicate?(package)
        end

        package.update_column(:status, params[:status]) if params[:status] && params[:status] != package.status

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

      def target_file_is_duplicate?(package)
        package.package_files.with_file_name(params[:file_name]).exists?
      end
    end
  end
end
