# frozen_string_literal: true

module Packages
  module Cargo
    class UpdatePackageFromMetadataService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze
      INVALID_METADATA_ERROR_MESSAGE = 'package name, version and/or index content not found in metadata'
      PROTECTED_PACKAGE_ERROR_MESSAGE = 'Package Protected'
      DUPLICATE_PACKAGE_ERROR_MESSAGE = 'Package already exists'

      InvalidMetadataError = Class.new(StandardError)
      ProtectedPackageError = Class.new(StandardError)
      DuplicatePackageError = Class.new(StandardError)

      def initialize(package_file, request_file, user_or_deploy_token)
        @package_file = package_file
        @request_file = request_file
        @user_or_deploy_token = user_or_deploy_token
      end

      def execute
        raise InvalidMetadataError, INVALID_METADATA_ERROR_MESSAGE unless valid_metadata?
        raise ProtectedPackageError, PROTECTED_PACKAGE_ERROR_MESSAGE if package_protected?
        raise DuplicatePackageError, DUPLICATE_PACKAGE_ERROR_MESSAGE if existing_package?

        try_obtain_lease do
          @package_file.transaction do
            process_package_update
          end
        end

      rescue ActiveRecord::RecordInvalid => e
        raise InvalidMetadataError, e.message
      end

      private

      def process_package_update
        update_linked_package
        create_metadatum

        replace_uploaded_file_with_extracted_crate
      end

      def valid_metadata?
        fields = [package_name, package_version, package_index_content]
        fields.all?(&:present?)
      end

      def existing_package?
        ::Packages::Cargo::Package.cargo_package_already_taken?(@package_file.project_id, package_name, package_version)
      end

      def package_protected?
        service_response =
          ::Packages::Protection::CheckRuleExistenceService.for_push(
            project: @package_file.project,
            current_user: @user_or_deploy_token,
            params: { package_name: package_name, package_type: :cargo }
          ).execute

        raise ArgumentError, service_response.message if service_response.error?

        service_response[:protection_rule_exists?]
      end

      def update_linked_package
        @package_file.package.update!(
          name: package_name,
          version: package_version,
          status: :default
        )
      end

      def create_metadatum
        @package_file.package.create_cargo_metadatum!(
          project: @package_file.project,
          index_content: package_index_content
        )
      end

      def package_name
        package_index_content[:name]
      end

      def package_version
        package_index_content[:vers]
      end

      def package_index_content
        metadata[:index_content]
      end

      def crate_data
        metadata[:crate_data]
      end

      def metadata
        response = ::Packages::Cargo::ExtractMetadataContentService
          .new(@request_file)
          .execute

        raise InvalidMetadataError, response.message if response.error?

        response.payload
      end
      strong_memoize_attr :metadata

      def package_filename
        "#{package_name}-#{package_version}.crate"
      end

      def lease_key
        package_id = @package_file.package_id
        "packages:cargo:update_package_from_metadata_service:package:#{package_id}"
      end

      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end

      def replace_uploaded_file_with_extracted_crate
        sha256 = Digest::SHA256.hexdigest(crate_data)

        file = CarrierWaveStringFile.new_file(
          file_content: crate_data,
          filename: package_filename,
          content_type: 'application/octet-stream'
        )

        @package_file.update!(
          file: file,
          file_name: package_filename,
          file_sha256: sha256,
          size: crate_data.bytesize
        )
      end
    end
  end
end
