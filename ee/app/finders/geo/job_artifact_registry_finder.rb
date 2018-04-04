module Geo
  class JobArtifactRegistryFinder < RegistryFinder
    def count_local_job_artifacts
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

    def count_synced_missing_on_primary_job_artifacts
      if aggregate_pushdown_supported?
        find_synced_missing_on_primary_job_artifacts.count
      else
        legacy_find_synced_missing_on_primary_job_artifacts.count
      end
    end

    def count_registry_job_artifacts
      Geo::JobArtifactRegistry.count
    end

    # Find limited amount of non replicated job artifacts.
    #
    # You can pass a list with `except_artifact_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_artifact_ids ids that will be ignored from the query
    def find_unsynced_job_artifacts(batch_size:, except_artifact_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_job_artifacts(except_artifact_ids: except_artifact_ids)
        else
          fdw_find_unsynced_job_artifacts(except_artifact_ids: except_artifact_ids)
        end

      relation.limit(batch_size)
    end

    def find_migrated_local_job_artifacts(batch_size:, except_artifact_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local_job_artifacts(except_artifact_ids: except_artifact_ids)
        else
          fdw_find_migrated_local_job_artifacts(except_artifact_ids: except_artifact_ids)
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

    def find_synced_job_artifacts_registries
      Geo::JobArtifactRegistry.synced
    end

    def find_synced_missing_on_primary_job_artifacts_registries
      Geo::JobArtifactRegistry.synced.missing_on_primary
    end

    def find_failed_job_artifacts_registries
      Geo::JobArtifactRegistry.failed
    end

    private

    def find_synced_job_artifacts
      if use_legacy_queries?
        legacy_find_synced_job_artifacts
      else
        fdw_find_job_artifacts.merge(find_synced_job_artifacts_registries)
      end
    end

    def find_synced_missing_on_primary_job_artifacts
      if use_legacy_queries?
        legacy_find_synced_missing_on_primary_job_artifacts
      else
        fdw_find_job_artifacts.merge(find_synced_missing_on_primary_job_artifacts_registries)
      end
    end

    def find_failed_job_artifacts
      if use_legacy_queries?
        legacy_find_failed_job_artifacts
      else
        fdw_find_job_artifacts.merge(find_failed_job_artifacts_registries)
      end
    end

    #
    # FDW accessors
    #

    def fdw_find_job_artifacts
      fdw_job_artifacts.joins("INNER JOIN job_artifact_registry ON job_artifact_registry.artifact_id = #{fdw_job_artifacts_table}.id")
        .with_files_stored_locally
    end

    def fdw_find_unsynced_job_artifacts(except_artifact_ids:)
      fdw_job_artifacts.joins("LEFT OUTER JOIN job_artifact_registry
                               ON job_artifact_registry.artifact_id = #{fdw_job_artifacts_table}.id")
        .with_files_stored_locally
        .where(job_artifact_registry: { id: nil })
        .where.not(id: except_artifact_ids)
    end

    def fdw_find_migrated_local_job_artifacts(except_artifact_ids:)
      fdw_job_artifacts.joins("INNER JOIN job_artifact_registry ON job_artifact_registry.artifact_id = #{fdw_job_artifacts_table}.id")
        .with_files_stored_remotely
        .where.not(id: except_artifact_ids)
        .merge(Geo::JobArtifactRegistry.all)
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
        find_synced_job_artifacts_registries.pluck(:artifact_id),
        Ci::JobArtifact
      )
    end

    def legacy_find_failed_job_artifacts
      legacy_inner_join_registry_ids(
        local_job_artifacts,
        find_failed_job_artifacts_registries.pluck(:artifact_id),
        Ci::JobArtifact
      )
    end

    def legacy_find_unsynced_job_artifacts(except_artifact_ids:)
      registry_artifact_ids = legacy_pluck_artifact_ids(include_registry_ids: except_artifact_ids)

      legacy_left_outer_join_registry_ids(
        local_job_artifacts,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end

    def legacy_pluck_artifact_ids(include_registry_ids:)
      ids = Geo::JobArtifactRegistry.pluck(:artifact_id)
      (ids + include_registry_ids).uniq
    end

    def legacy_find_migrated_local_job_artifacts(except_artifact_ids:)
      registry_file_ids = Geo::JobArtifactRegistry.pluck(:artifact_id) - except_artifact_ids

      legacy_inner_join_registry_ids(
        job_artifacts.with_files_stored_remotely,
        registry_file_ids,
        Ci::JobArtifact
      )
    end

    def legacy_find_synced_missing_on_primary_job_artifacts
      legacy_inner_join_registry_ids(
        local_job_artifacts,
        find_synced_missing_on_primary_job_artifacts_registries.pluck(:artifact_id),
        Ci::JobArtifact
      )
    end
  end
end
