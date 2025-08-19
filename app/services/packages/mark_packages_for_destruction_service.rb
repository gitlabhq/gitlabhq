# frozen_string_literal: true

module Packages
  class MarkPackagesForDestructionService
    include BaseServiceUtility

    BATCH_SIZE = 20

    UNAUTHORIZED_RESPONSE = ServiceResponse.error(
      message: "You don't have the permission to perform this action",
      reason: :unauthorized
    ).freeze

    ERROR_RESPONSE = ServiceResponse.error(
      message: 'Failed to mark the packages as pending destruction'
    ).freeze

    SUCCESS_RESPONSE = ServiceResponse.success(
      message: 'Packages were successfully marked as pending destruction'
    ).freeze

    # Initialize this service with the given packages and user.
    #
    # * `packages`: must be an ActiveRecord relationship.
    # * `current_user`: an User object. Could be nil.
    def initialize(packages:, current_user: nil)
      @packages = packages
      @current_user = current_user
    end

    def execute(batch_size: BATCH_SIZE)
      no_access = false
      min_batch_size = [batch_size, BATCH_SIZE].min
      package_ids = []

      packages.each_batch(of: min_batch_size) do |batched_packages|
        loaded_packages = batched_packages.including_project_route.to_a
        package_ids = loaded_packages.map(&:id)

        break no_access = true unless can_destroy_packages?(loaded_packages)

        ::Packages::Package.id_in(package_ids)
                           .update_all(status: :pending_destruction)

        after_marked_for_destruction(loaded_packages)
      end

      return UNAUTHORIZED_RESPONSE if no_access

      SUCCESS_RESPONSE
    rescue StandardError => e
      track_exception(e, package_ids)
      ERROR_RESPONSE
    end

    private

    attr_reader :packages, :current_user

    def after_marked_for_destruction(packages)
      sync_maven_metadata(packages)
      sync_npm_metadata(packages)
      sync_helm_metadata(packages)
      mark_package_files_for_destruction(packages)
    end

    def mark_package_files_for_destruction(packages)
      ::Packages::MarkPackageFilesForDestructionWorker.bulk_perform_async_with_contexts(
        packages,
        arguments_proc: ->(package) { package.id },
        context_proc: ->(package) { { project: package.project, user: current_user } }
      )
    end

    def sync_maven_metadata(packages)
      maven_packages_with_version = packages.select { |pkg| pkg.maven? && pkg.version? }
      ::Packages::Maven::Metadata::SyncWorker.bulk_perform_async_with_contexts(
        maven_packages_with_version,
        arguments_proc: ->(package) { [current_user.id, package.project_id, package.name] },
        context_proc: ->(package) { { project: package.project, user: current_user } }
      )
    end

    def sync_npm_metadata(packages)
      npm_packages = packages.select(&:npm?)
      ::Packages::Npm::CreateMetadataCacheWorker.bulk_perform_async_with_contexts(
        npm_packages,
        arguments_proc: ->(package) { [package.project_id, package.name] },
        context_proc: ->(package) { { project: package.project, user: current_user } }
      )
    end

    def sync_helm_metadata(packages)
      helm_packages = packages.select(&:helm?)

      files = ::Packages::PackageFile.most_recent_for(
        ::Packages::Package.id_in(helm_packages.map(&:id)),
        extra_join: :helm_file_metadatum
      ).preload_helm_file_metadata
        .preload_project

      grouped = files.group_by { |f| [f.project_id, f.helm_file_metadatum.channel] }
      file_with_metadata_infos = grouped.map do |(_, channel), files|
        {
          channel: channel,
          project: files.first.package.project
        }
      end

      ::Packages::Helm::CreateMetadataCacheWorker.bulk_perform_async_with_contexts(
        file_with_metadata_infos,
        arguments_proc: ->(hash) { [hash[:project].id, hash[:channel]] },
        context_proc: ->(hash) { { project: hash[:project], user: current_user } }
      )
    end

    def can_destroy_packages?(packages)
      packages.all? do |package|
        can?(current_user, :destroy_package, package)
      end
    end

    def track_exception(error, package_ids)
      Gitlab::ErrorTracking.track_exception(error, package_ids: package_ids)
    end
  end
end

Packages::MarkPackagesForDestructionService.prepend_mod
