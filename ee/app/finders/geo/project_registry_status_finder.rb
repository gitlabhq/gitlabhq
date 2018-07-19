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
      Geo::ProjectRegistry.all.includes(:project)
    end

    # Return any project registry which project is pending to update
    #
    # We include here only projects that have successfully synced before.
    # We exclude projects that have tried to resync already and had failures
    def pending_projects
      no_repository_sync_failure = project_registry[:repository_retry_count].eq(nil)
      no_wiki_sync_failure = project_registry[:wiki_retry_count].eq(nil)

      Geo::ProjectRegistry.where(
        project_registry[:resync_repository].eq(true)
          .or(project_registry[:resync_wiki].eq(true))
        .and(no_repository_sync_failure.and(no_wiki_sync_failure))
      ).includes(:project)
    end

    # Return any project registry which project has a failure
    #
    # Both types of failures are included: Synchronization and Verification
    def failed_projects
      Geo::ProjectRegistry.failed.includes(:project)
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

      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON (project_registry.project_id = #{Geo::Fdw::Project.table_name}.id)").where(no_project_registry.or(no_repository_synced)).includes(:project_registry)
    end

    private

    def project_registry
      Geo::ProjectRegistry.arel_table
    end
  end
end
