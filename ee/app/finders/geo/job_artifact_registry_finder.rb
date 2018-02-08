module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    def count_job_artifacts
      job_artifacts.count
    end

    def count_synced_job_artifacts
      relation =
        if selective_sync?
          legacy_find_synced_job_artifacts
        else
          find_synced_job_artifacts_registries
        end

      relation.count
    end

    def count_failed_job_artifacts
      relation =
        if selective_sync?
          legacy_find_failed_job_artifacts
        else
          find_failed_job_artifacts_registries
        end

      relation.count
    end

    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_registry_ids:` so you can exclude items you
    # already scheduled but haven't finished and persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_registry_ids ids that will be ignored from the query
    def find_unsynced_job_artifacts(batch_size:, except_registry_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_job_artifacts(except_registry_ids: except_registry_ids)
        else
          fdw_find_unsynced_job_artifacts(except_registry_ids: except_registry_ids)
        end

      relation.limit(batch_size)
    end

    def job_artifacts
      relation =
        if selective_sync?
          Ci::JobArtifact.joins(:project).where(projects: { id: current_node.projects })
        else
          Ci::JobArtifact.all
        end

      relation.with_files_stored_locally
    end

    private

    def find_synced_job_artifacts_registries
      Geo::FileRegistry.job_artifacts.synced
    end

    def find_failed_job_artifacts_registries
      Geo::FileRegistry.job_artifacts.failed
    end

    #
    # FDW accessors
    #

    def fdw_find_unsynced_job_artifacts(except_registry_ids:)
      fdw_table = Geo::Fdw::Ci::JobArtifact.table_name

      Geo::Fdw::Ci::JobArtifact.joins("LEFT OUTER JOIN file_registry
                                              ON file_registry.file_id = #{fdw_table}.id
                                             AND file_registry.file_type = 'job_artifact'")
        .with_files_stored_locally
        .where(file_registry: { id: nil })
        .where.not(id: except_registry_ids)
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_job_artifacts
      legacy_inner_join_registry_ids(
        job_artifacts,
        find_synced_job_artifacts_registries.pluck(:file_id),
        Ci::JobArtifact
      )
    end

    def legacy_find_failed_job_artifacts
      legacy_inner_join_registry_ids(
        job_artifacts,
        find_failed_job_artifacts_registries.pluck(:file_id),
        Ci::JobArtifact
      )
    end

    def legacy_find_unsynced_job_artifacts(except_registry_ids:)
      registry_ids = legacy_pluck_registry_ids(file_types: :job_artifact, except_registry_ids: except_registry_ids)

      legacy_left_outer_join_registry_ids(
        job_artifacts,
        registry_ids,
        Ci::JobArtifact
      )
    end
  end
end
