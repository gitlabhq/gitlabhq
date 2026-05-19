# frozen_string_literal: true

module Packages
  class MarkPackageForDestructionService < BaseContainerService
    alias_method :package, :container

    def initialize(container:, current_user: nil, skip_protection_check: false)
      super(container:, current_user:)
      @skip_protection_check = skip_protection_check
    end

    def execute
      return service_response_error("You don't have access to this package", 403) unless user_can_delete_package?
      return service_response_error('Package is deletion protected.', 403) if deletion_protected?

      package.pending_destruction!

      package.mark_package_files_for_destruction
      package.sync_maven_metadata(current_user) if package.maven?
      package.sync_npm_metadata_cache if package.npm?
      sync_helm_metadata_caches(current_user) if package.helm?

      ::Packages::CreateEventService
        .new(package.project, current_user, event_name: 'delete_package', scope: package)
        .execute

      service_response_success('Package was successfully marked as pending destruction')
    rescue StandardError => e
      track_exception(e)
      service_response_error('Failed to mark the package as pending destruction', 400)
    end

    private

    attr_reader :skip_protection_check

    def deletion_protected?
      return false if skip_protection_check
      return false if ::Feature.disabled?(:packages_protected_packages_delete, package.project)

      ::Packages::Protection::CheckRuleExistenceService.for_delete(
        project: package.project,
        current_user: current_user,
        params: { package_name: package.name, package_type: package.package_type }
      ).execute[:protection_rule_exists?]
    end

    def service_response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end

    def service_response_success(message)
      ServiceResponse.success(message: message)
    end

    def user_can_delete_package?
      can?(current_user, :destroy_package, package.project)
    end

    def track_exception(error)
      Gitlab::ErrorTracking.track_exception(
        error,
        project_id: package.project_id,
        package_id: package.id
      )
    end

    def sync_helm_metadata_caches(user)
      Packages::Helm::BulkSyncHelmMetadataCacheService.new(
        user, package.package_files
      ).execute
    end
  end
end

Packages::MarkPackageForDestructionService.prepend_mod
