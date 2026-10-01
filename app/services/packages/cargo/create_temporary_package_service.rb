# frozen_string_literal: true

module Packages
  module Cargo
    class CreateTemporaryPackageService < ::Packages::CreateTemporaryPackageService
      # The crate name and version are only known once the worker parses the
      # publish body, so the package file gets a placeholder name that
      # UpdatePackageFromMetadataService overwrites.
      PACKAGE_FILE_NAME = 'package.crate'

      ERRORS = {
        unauthorized: ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized)
      }.freeze

      def execute
        return ERRORS[:unauthorized] unless can_create_package?
        return ERROR_RESPONSE_PACKAGE_PROTECTED if crate_name_protected?

        package, package_file = ApplicationRecord.transaction do
          package = super(::Packages::Cargo::Package, name: ::Packages::Cargo::TEMPORARY_PACKAGE_NAME)
          package_file = ::Packages::CreatePackageFileService.new(package, file_params).execute

          [package, package_file]
        end

        ::Packages::Cargo::ExtractionWorker.perform_async(package_file.id, worker_params)

        ServiceResponse.success(payload: { package: package })
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message, reason: :invalid_parameter)
      end

      private

      # npm refuses a protected name before creating anything, and cargo can
      # too: the name sits in the metadata at the front of the publish body.
      # A body this cannot read falls through to the worker, which already
      # raises on invalid metadata and on a protected name.
      def crate_name_protected?
        response = ::Packages::Cargo::ExtractMetadataContentService.new(params[:file]).execute_index_only
        return false if response.error?

        crate_name = response.payload.dig(:index_content, :name)
        return false if crate_name.blank?

        package_protected?(package_name: crate_name, package_type: :cargo)
      end

      # No status: the worker looks the file up with `not_processing`.
      def file_params
        {
          build: params[:build],
          file: params[:file],
          file_name: PACKAGE_FILE_NAME,
          size: params[:file].size
        }
      end

      # String keys: Sidekiq rejects symbols as job arguments.
      def worker_params
        current_user.is_a?(DeployToken) ? { 'deploy_token_id' => current_user.id } : { 'user_id' => current_user.id }
      end
    end
  end
end
