# frozen_string_literal: true

module Packages
  module Nuget
    class CreateOrUpdatePackageService < BaseService
      include ::Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      # used by ExclusiveLeaseGuard
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i.freeze

      DUPLICATE_ERROR = ServiceResponse.error(
        message: 'A package with the same name and version already exists',
        reason: :conflict
      ).freeze

      LEASE_TAKEN_ERROR = ServiceResponse.error(
        message: 'Failed to obtain a lock. Please try again.',
        reason: :conflict
      ).freeze

      def execute
        return DUPLICATE_ERROR unless ::Namespace::PackageSetting.duplicates_allowed?(existing_package)

        package = try_obtain_lease { process_package }

        return LEASE_TAKEN_ERROR unless package

        ServiceResponse.success(payload: { package: })
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message, reason: :bad_request)
      end

      private

      def existing_package
        ::Packages::Nuget::PackageFinder
          .new(
            current_user,
            project,
            package_name: metadata[:package_name],
            package_version: metadata[:package_version]
          )
          .execute
          .first
      end
      strong_memoize_attr :existing_package

      def process_package
        ApplicationRecord.transaction do
          create_package_file
          sync_metadatum
          update_tags
          create_build_infos
          create_dependencies
        end

        target_package
      end

      def create_package_file
        ::Packages::CreatePackageFileService
          .new(target_package, params.merge(file_name: package_filename))
          .execute
      end

      def sync_metadatum
        ::Packages::Nuget::SyncMetadatumService
          .new(target_package, metadata.slice(:authors, :description, :project_url, :license_url, :icon_url))
          .execute
      end

      def update_tags
        ::Packages::UpdateTagsService
          .new(target_package, metadata.fetch(:package_tags, []))
          .execute
      end

      def create_build_infos
        target_package.create_build_infos!(params[:build])
      end

      def create_dependencies
        return if existing_package

        ::Packages::Nuget::CreateDependencyService
          .new(target_package, metadata.fetch(:package_dependencies, []))
          .execute
      end

      def target_package
        existing_package || create_new_package
      end
      strong_memoize_attr :target_package

      def create_new_package
        ::Packages::Nuget::Package.create!(
          name: metadata[:package_name],
          version: metadata[:package_version],
          project: project,
          creator: current_user.is_a?(User) ? current_user : nil
        )
      end

      def package_filename
        "#{metadata[:package_name].downcase}.#{metadata[:package_version].downcase}.nupkg"
      end

      def metadata
        ::Packages::Nuget::ExtractMetadataContentService
          .new(params[:nuspec_file_content])
          .execute
          .payload
      end
      strong_memoize_attr :metadata

      # used by ExclusiveLeaseGuard
      def lease_key
        "#{self.class.name.underscore}:#{project.id}_#{metadata[:package_name]}_#{metadata[:package_version]}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
