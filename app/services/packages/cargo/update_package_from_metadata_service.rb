# frozen_string_literal: true

module Packages
  module Cargo
    class UpdatePackageFromMetadataService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze
      # `2` tells Cargo the entry may use `dep:` feature syntax.
      INDEX_FORMAT_VERSION = 2
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
        fields = [package_name, package_version, publish_metadata]
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
        publish_metadata[:name]
      end

      def package_version
        publish_metadata[:vers]
      end

      # What the client uploads is the crate manifest, not an index entry: it
      # carries authorship and documentation keys the index schema rejects, and
      # omits `cksum`, which only the server can compute. Translate rather than
      # store verbatim.
      # https://doc.rust-lang.org/cargo/reference/registry-index.html#json-schema
      def package_index_content
        content = {
          name: package_name,
          vers: package_version,
          deps: index_deps,
          cksum: crate_sha256,
          features: publish_metadata[:features] || {},
          yanked: false,
          links: publish_metadata[:links],
          v: INDEX_FORMAT_VERSION
        }

        content[:rust_version] = publish_metadata[:rust_version] if publish_metadata[:rust_version].present?

        content
      end
      strong_memoize_attr :package_index_content

      # The manifest names a dependency's range `version_req`; the index calls
      # it `req`. A renamed dependency splits in two: `name` holds the alias and
      # `package` the crate it points at.
      def index_deps
        Array(publish_metadata[:deps]).map do |dep|
          dep = dep.dup
          dep[:req] = dep.delete(:version_req) if dep.key?(:version_req)
          explicit_name = dep.delete(:explicit_name_in_toml)

          if explicit_name.present?
            dep[:package] = dep[:name]
            dep[:name] = explicit_name
          end

          dep
        end
      end

      def publish_metadata
        metadata[:index_content]
      end

      def crate_sha256
        Digest::SHA256.hexdigest(crate_data)
      end
      strong_memoize_attr :crate_sha256

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
        file = CarrierWaveStringFile.new_file(
          file_content: crate_data,
          filename: package_filename,
          content_type: 'application/octet-stream'
        )

        @package_file.update!(
          file: file,
          file_name: package_filename,
          file_sha256: crate_sha256,
          size: crate_data.bytesize
        )
      end
    end
  end
end
