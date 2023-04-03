# frozen_string_literal: true

module Packages
  module Debian
    class ProcessPackageFileService
      include ExclusiveLeaseGuard
      include Gitlab::Utils::StrongMemoize

      SOURCE_FIELD_SPLIT_REGEX = /[ ()]/
      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      def initialize(package_file, distribution_name, component_name)
        @package_file = package_file
        @distribution_name = distribution_name
        @component_name = component_name
      end

      def execute
        return if @package_file.package.pending_destruction?

        validate!

        try_obtain_lease do
          package.transaction do
            rename_package_and_set_version
            update_package
            update_file_metadata
            cleanup_temp_package
          end

          ::Packages::Debian::GenerateDistributionWorker.perform_async(:project, package.debian_distribution.id)
        end
      end

      private

      def validate!
        raise ArgumentError, 'missing distribution name' unless @distribution_name.present?
        raise ArgumentError, 'missing component name' unless @component_name.present?
        raise ArgumentError, 'package file without Debian metadata' unless @package_file.debian_file_metadatum
        raise ArgumentError, 'already processed package file' unless @package_file.debian_file_metadatum.unknown?

        if file_metadata[:file_type] == :deb || file_metadata[:file_type] == :udeb || file_metadata[:file_type] == :ddeb
          return
        end

        raise ArgumentError, "invalid package file type: #{file_metadata[:file_type]}"
      end

      def file_metadata
        ::Packages::Debian::ExtractMetadataService.new(@package_file).execute
      end
      strong_memoize_attr :file_metadata

      def package
        packages = temp_package.project
                               .packages
                               .existing_debian_packages_with(name: package_name, version: package_version)
        package = packages.with_debian_codename_or_suite(@distribution_name)
                          .first

        unless package
          package_in_other_distribution = packages.first

          if package_in_other_distribution
            raise ArgumentError, "Debian package #{package_name} #{package_version} exists " \
                                 "in distribution #{package_in_other_distribution.debian_distribution.codename}"
          end
        end

        package || temp_package
      end
      strong_memoize_attr :package

      def temp_package
        @package_file.package
      end
      strong_memoize_attr :temp_package

      def package_name
        package_name_and_version[0]
      end

      def package_version
        package_name_and_version[1]
      end

      def package_name_and_version
        package_name = file_metadata[:fields]['Package']
        package_version = file_metadata[:fields]['Version']

        if file_metadata[:fields]['Source']
          # "sample" or "sample (1.2.3~alpha2)"
          source_field_parts = file_metadata[:fields]['Source'].split(SOURCE_FIELD_SPLIT_REGEX)
          package_name = source_field_parts[0]
          package_version = source_field_parts[2] || package_version
        end

        [package_name, package_version]
      end
      strong_memoize_attr :package_name_and_version

      def rename_package_and_set_version
        package.update!(
          name: package_name,
          version: package_version,
          status: :default
        )
      end

      def update_package
        return unless using_temporary_package?

        package.update!(
          debian_publication_attributes: { distribution_id: distribution.id }
        )
      end

      def using_temporary_package?
        package.id == temp_package.id
      end

      def distribution
        Packages::Debian::DistributionsFinder.new(
          @package_file.package.project,
          codename_or_suite: @distribution_name
        ).execute.last!
      end
      strong_memoize_attr :distribution

      def update_file_metadata
        ::Packages::UpdatePackageFileService.new(@package_file, package_id: package.id)
          .execute

        # Force reload from database, as package has changed
        @package_file.reload_package

        @package_file.debian_file_metadatum.update!(
          file_type: file_metadata[:file_type],
          component: @component_name,
          architecture: file_metadata[:architecture],
          fields: file_metadata[:fields]
        )
      end

      def cleanup_temp_package
        temp_package.destroy unless using_temporary_package?
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:debian:process_package_file_service:package_file:#{@package_file.id}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
