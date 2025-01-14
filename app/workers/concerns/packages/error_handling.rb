# frozen_string_literal: true

module Packages
  module ErrorHandling
    extend ActiveSupport::Concern

    DEFAULT_STATUS_MESSAGE = 'Unexpected error'

    CONTROLLED_ERRORS = [
      ArgumentError,
      ActiveRecord::RecordInvalid,
      ::Packages::Helm::ExtractFileMetadataService::ExtractionError,
      ::Packages::Nuget::ExtractMetadataFileService::ExtractionError,
      ::Packages::Nuget::UpdatePackageFromMetadataService::InvalidMetadataError,
      ::Packages::Nuget::UpdatePackageFromMetadataService::ZipError,
      ::Packages::Nuget::UpdatePackageFromMetadataService::DuplicatePackageError,
      ::Packages::Rubygems::ProcessGemService::ExtractionError,
      ::Packages::Rubygems::ProcessGemService::InvalidMetadataError,
      ::Packages::Npm::ProcessPackageFileService::ExtractionError,
      ::Packages::Npm::CheckManifestCoherenceService::MismatchError
    ].freeze

    def process_package_file_error(package_file:, exception:, extra_log_payload: {})
      log_payload = {
        project_id: package_file.project_id,
        package_file_id: package_file.id
      }.merge(extra_log_payload)
      Gitlab::ErrorTracking.log_exception(exception, **log_payload)

      package_file.package.update_columns(
        status: :error,
        status_message: truncated_status_message(exception)
      )
    end

    private

    def controlled_error?(exception)
      CONTROLLED_ERRORS.include?(exception.class)
    end

    def truncated_status_message(exception)
      status_message = exception.message if controlled_error?(exception)

      # Do not save the exception message in case it contains confidential data
      status_message ||= "#{DEFAULT_STATUS_MESSAGE}: #{exception.class}"

      status_message.truncate(::Packages::Package::STATUS_MESSAGE_MAX_LENGTH)
    end
  end
end
