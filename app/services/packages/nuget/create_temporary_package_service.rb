# frozen_string_literal: true

module Packages
  module Nuget
    class CreateTemporaryPackageService
      ERRORS = {
        failed_to_create_temporary_package: ServiceResponse.error(message: 'Failed to create temporary package'),
        failed_to_create_package_file: ServiceResponse.error(message: 'Failed to create package file')
      }.freeze

      def initialize(project:, user:, params: {})
        @project = project
        @user = user
        @package_params = params[:package_params]
        @package_file_params = params[:package_file_params]
      end

      def execute
        response = ERRORS[:failed_to_create_temporary_package]

        # Transaction to cover temporary package and package file creation
        ApplicationRecord.transaction do
          response = create_temporary_package
          raise ActiveRecord::Rollback if response.error?

          response = create_package_file(response.payload[:package])
          raise ActiveRecord::Rollback if response.error?
        end

        return response if response.error?

        # Enqueued outside of transaction to avoid blocking and to ensure jobs are only enqueued on success
        ::Packages::Nuget::ExtractionWorker.perform_async(response.payload[:package_file].id)

        response
      end

      private

      attr_reader :project, :user, :package_params, :package_file_params

      def create_temporary_package
        package = ::Packages::CreateTemporaryPackageService.new(
          project, user, package_params
        ).execute(:nuget, name: package_params[:name])

        return ERRORS[:failed_to_create_temporary_package] if package.blank?

        ServiceResponse.success(payload: { package: package })
      end

      def create_package_file(package)
        package_file = ::Packages::CreatePackageFileService.new(package, package_file_params).execute

        return ERRORS[:failed_to_create_package_file] if package_file.blank?

        ServiceResponse.success(payload: { package_file: package_file })
      end
    end
  end
end
