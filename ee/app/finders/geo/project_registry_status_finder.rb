# frozen_string_literal: true

module Geo
  # Finders specific for Project status listing and inspecting
  #
  # This finders works slightly different than the ones used to trigger
  # synchronization, as we are concerned in filtering for displaying rather then
  # filtering for processing.
  class ProjectRegistryStatusFinder < RegistryFinder
    # Returns any project registry which project is fully synced
    #
    # We consider fully synced any project without pending actions
    # or failures
    def synced_projects
      no_repository_resync = project_registry[:resync_repository].eq(false)
      no_repository_sync_failure = project_registry[:repository_retry_count].eq(nil)
      repository_verified = project_registry[:repository_verification_checksum_sha].not_eq(nil)

      Geo::ProjectRegistry.where(
        no_repository_resync
          .and(no_repository_sync_failure)
          .and(repository_verified)
      ).includes(:project)
    end

    # Return any project registry which project is pending to update
    #
    # We include here only projects that have successfully synced before.
    # We exclude projects that have tried to re-sync or re-check already and had failures
    def pending_projects
      no_repository_sync_failure = project_registry[:repository_retry_count].eq(nil)
      repository_successfully_synced_before = project_registry[:last_repository_successful_sync_at].not_eq(nil)
      repository_pending_verification = project_registry[:repository_verification_checksum_sha].eq(nil)
      repository_without_verification_failure_before = project_registry[:last_repository_verification_failure].eq(nil)
      flagged_for_resync = project_registry[:resync_repository].eq(true)

      Geo::ProjectRegistry.where(
        no_repository_sync_failure
          .and(repository_successfully_synced_before)
          .and(flagged_for_resync
            .or(repository_pending_verification
              .and(repository_without_verification_failure_before)))
      ).includes(:project)
    end

    # Return any project registry which project has a failure
    #
    # Both types of failures are included: Synchronization and Verification
    def failed_projects
      repository_sync_failed = project_registry[:repository_retry_count].gt(0)
      repository_verification_failed = project_registry[:last_repository_verification_failure].not_eq(nil)
      repository_checksum_mismatch = project_registry[:repository_checksum_mismatch].eq(true)

      Geo::ProjectRegistry.where(
        repository_sync_failed
          .or(repository_verification_failed)
          .or(repository_checksum_mismatch)
      ).includes(:project)
    end

    # Return projects that has never been fully synced
    #
    # We include here both projects without a corresponding ProjectRegistry
    # or projects that have never successfully synced.
    #
    # @return [Geo::Fdw::Project] Projects that has never been fully synced
    def never_synced_projects
      no_project_registry = project_registry[:project_id].eq(nil)
      no_repository_synced = project_registry[:last_repository_successful_sync_at].eq(nil)

      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON (project_registry.project_id = #{Geo::Fdw::Project.table_name}.id)")
        .where(
          no_project_registry
            .or(no_repository_synced)
        ).includes(:project_registry)
    end

    private

    def project_registry
      Geo::ProjectRegistry.arel_table
    end
  end
end
