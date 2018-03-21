module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    def count_job_artifacts
      local_job_artifacts.count
    end

    def count_synced_job_artifacts
      if aggregate_pushdown_supported?
        find_synced_job_artifacts.count
      else
        legacy_find_synced_job_artifacts.count
      end
    end

    def count_failed_job_artifacts
      if aggregate_pushdown_supported?
        find_failed_job_artifacts.count
      else
        legacy_find_failed_job_artifacts.count
      end
    end

    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_file_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_file_ids ids that will be ignored from the query
    def find_unsynced_job_artifacts(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_job_artifacts(except_file_ids: except_file_ids)
        else
          fdw_find_unsynced_job_artifacts(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end

    def job_artifacts
      if selective_sync?
        Ci::JobArtifact.joins(:project).where(projects: { id: current_node.projects })
      else
        Ci::JobArtifact.all
      end
    end

    def local_job_artifacts
      job_artifacts.with_files_stored_locally
    end

    private

    def find_synced_job_artifacts
      if use_legacy_queries?
        legacy_find_synced_job_artifacts
      else
        fdw_find_job_artifacts.merge(Geo::FileRegistry.synced)
      end
    end

    def find_failed_job_artifacts
      if use_legacy_queries?
        legacy_find_failed_job_artifacts
      else
        fdw_find_job_artifacts.merge(Geo::FileRegistry.failed)
      end
    end

    #
    # FDW accessors
    #

    def fdw_find_job_artifacts
      fdw_job_artifacts.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_job_artifacts_table}.id")
        .with_files_stored_locally
        .merge(Geo::FileRegistry.job_artifacts)
    end

    def fdw_find_unsynced_job_artifacts(except_file_ids:)
      fdw_job_artifacts.joins("LEFT OUTER JOIN file_registry
                                            ON file_registry.file_id = #{fdw_job_artifacts_table}.id
                                           AND file_registry.file_type = 'job_artifact'")
        .with_files_stored_locally
        .where(file_registry: { id: nil })
        .where.not(id: except_file_ids)
    end

    def fdw_job_artifacts
      if selective_sync?
        Geo::Fdw::Ci::JobArtifact.joins(:project).where(projects: { id: current_node.projects })
      else
        Geo::Fdw::Ci::JobArtifact.all
      end
    end

    def fdw_job_artifacts_table
      Geo::Fdw::Ci::JobArtifact.table_name
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_job_artifacts
      legacy_inner_join_registry_ids(
        local_job_artifacts,
        Geo::FileRegistry.job_artifacts.synced.pluck(:file_id),
        Ci::JobArtifact
      )
    end

    def legacy_find_failed_job_artifacts
      legacy_inner_join_registry_ids(
        local_job_artifacts,
        Geo::FileRegistry.job_artifacts.failed.pluck(:file_id),
        Ci::JobArtifact
      )
    end

    def legacy_find_unsynced_job_artifacts(except_file_ids:)
      registry_file_ids = legacy_pluck_registry_file_ids(file_types: :job_artifact) | except_file_ids

      legacy_left_outer_join_registry_ids(
        local_job_artifacts,
        registry_file_ids,
        Ci::JobArtifact
      )
    end
  end
end
