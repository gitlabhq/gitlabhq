# frozen_string_literal: true

module Packages
  module Cargo
    class CreateTemporaryPackageService < ::Packages::CreateTemporaryPackageService
      # The crate name and version are only known once the worker parses the
      # publish body, so the package file gets a placeholder name that
      # UpdatePackageFromMetadataService overwrites.
      PACKAGE_FILE_NAME = 'package.crate'

      ERRORS = {
        unauthorized: ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized),
        package_already_exists: ServiceResponse.error(
          message: 'Package already exists', reason: :package_already_exists
        )
      }.freeze

      def execute
        return ERRORS[:unauthorized] unless can_create_package?

        publish_error = check_publish_metadata
        return publish_error if publish_error

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

      # Unreadable uploads skip these checks; the worker runs them later.
      def check_publish_metadata
        index_content = read_index_content
        return unless index_content

        name, version = index_content.values_at(:name, :vers)
        return if name.blank?
        # Malformed values (e.g. `"vers": 1`) would raise here; leave them to the worker.
        return unless [name, version].compact.all?(String)

        return ERROR_RESPONSE_PACKAGE_PROTECTED if package_protected?(package_name: name, package_type: :cargo)

        ERRORS[:package_already_exists] if version.present? &&
          ::Packages::Cargo::Package.cargo_package_already_taken?(project.id, name, version)
      end

      def read_index_content
        with_publish_body do |body|
          response = ::Packages::Cargo::ExtractMetadataContentService.new(body).execute_index_only
          response.payload[:index_content] if response.success?
        end
      end

      # Body is already in storage; read only its start, not the crate.
      def with_publish_body(&block)
        file = params[:file]
        return yield(file) if file.remote_id.blank?

        uploader = ::Packages::PackageFileUploader.new(::Packages::PackageFile.new, :file)
        uploader.cache!(file)
        uploader.open(&block)
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
