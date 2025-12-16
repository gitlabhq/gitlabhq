# frozen_string_literal: true

module Packages
  module Npm
    class CreateTemporaryPackageService < ::Packages::CreateTemporaryPackageService
      CONTENT_TYPE = 'application/json'

      ERRORS = {
        unauthorized: ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized)
      }.freeze

      def execute
        return ERRORS[:unauthorized] unless can_create_package?
        return ERROR_RESPONSE_PACKAGE_PROTECTED if package_protected?(package_name: name, package_type: :npm)

        package, package_file = ApplicationRecord.transaction do
          package = super(::Packages::Npm::Package, name: name)
          package_file = ::Packages::CreatePackageFileService.new(package, file_params).execute

          [package, package_file]
        end

        ::Packages::Npm::ProcessTemporaryPackageFileWorker.perform_async(
          current_user.id,
          package_file.id,
          params[:deprecate]
        )

        ServiceResponse.success(payload: { package: package })
      rescue ActiveRecord::RecordInvalid => e
        reason = e.record.errors.of_kind?(:name, :taken) ? :name_taken : :invalid_parameter
        ServiceResponse.error(message: e.message, reason: reason)
      end

      private

      def name
        params[:package_name]
      end

      def file_params
        {
          build: params[:build],
          file: params[:file],
          file_name: "#{name}-#{version}.json",
          file_sha1: params[:file].sha1,
          size: params[:file].size,
          content_type: CONTENT_TYPE,
          status: :processing
        }
      end
    end
  end
end
