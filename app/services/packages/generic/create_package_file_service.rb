# frozen_string_literal: true

module Packages
  module Generic
    class CreatePackageFileService < BaseService
      def execute
        ::Packages::Package.transaction do
          package_file = create_package_file(find_or_create_package)
          ServiceResponse.success(payload: { package_file: package_file })
        end
      rescue ::Packages::DuplicatePackageError => e
        ServiceResponse.error(message: e.message, reason: :package_file_already_exists)
      rescue ::Packages::PackageProtectedError
        ::Packages::CreatePackageService::ERROR_RESPONSE_PACKAGE_PROTECTED
      end

      private

      def find_or_create_package
        package_params = {
          name: params[:package_name],
          version: params[:package_version],
          build: params[:build],
          status: params[:status]
        }

        response = ::Packages::Generic::FindOrCreatePackageService
          .new(project, current_user, package_params)
          .execute

        raise ::Packages::PackageProtectedError, response.message if response.cause.package_protected?

        package = response[:package]

        unless Namespace::PackageSetting.duplicates_allowed?(package)
          raise ::Packages::DuplicatePackageError if target_file_is_duplicate?(package)
        end

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

      def target_file_is_duplicate?(package)
        package
          .package_files
          .with_file_name(params[:file_name])
          .not_pending_destruction
          .exists?
      end
    end
  end
end
