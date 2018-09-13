module Geo
  class JobArtifactRegistryFinder < RegistryFinder
    def count_syncable
      syncable.count
    end

    def count_synced
      if aggregate_pushdown_supported?
        find_synced.count
      else
        legacy_find_synced.count
      end
    end

    def count_failed
      if aggregate_pushdown_supported?
        find_failed.count
      else
        legacy_find_failed.count
      end
    end

    def count_synced_missing_on_primary
      if aggregate_pushdown_supported?
        find_synced_missing_on_primary.count
      else
        legacy_find_synced_missing_on_primary.count
      end
    end

    def count_registry
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
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_artifact_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced(except_artifact_ids: except_artifact_ids)
        else
          fdw_find_unsynced(except_artifact_ids: except_artifact_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_artifact_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local(except_artifact_ids: except_artifact_ids)
        else
          fdw_find_migrated_local(except_artifact_ids: except_artifact_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def syncable
      all.geo_syncable
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_artifact_ids: [])
      find_failed_registries
        .retry_due
        .where.not(artifact_id: except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_artifact_ids: [])
      find_synced_missing_on_primary_registries
        .retry_due
        .where.not(artifact_id: except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def all
      if selective_sync?
        Ci::JobArtifact.joins(:project).where(projects: { id: current_node.projects })
      else
        Ci::JobArtifact.all
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_synced
      if use_legacy_queries?
        legacy_find_synced
      else
        fdw_find.merge(find_synced_registries)
      end
    end

    def find_synced_missing_on_primary
      if use_legacy_queries?
        legacy_find_synced_missing_on_primary
      else
        fdw_find.merge(find_synced_missing_on_primary_registries)
      end
    end

    def find_failed
      if use_legacy_queries?
        legacy_find_failed
      else
        fdw_find.merge(find_failed_registries)
      end
    end

    def find_synced_registries
      Geo::JobArtifactRegistry.synced
    end

    def find_synced_missing_on_primary_registries
      find_synced_registries.missing_on_primary
    end

    def find_failed_registries
      Geo::JobArtifactRegistry.failed
    end

    #
    # FDW accessors
    #

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find
      fdw_all.joins("INNER JOIN job_artifact_registry ON job_artifact_registry.artifact_id = #{fdw_table}.id")
        .geo_syncable
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_unsynced(except_artifact_ids:)
      fdw_all.joins("LEFT OUTER JOIN job_artifact_registry
                               ON job_artifact_registry.artifact_id = #{fdw_table}.id")
        .geo_syncable
        .where(job_artifact_registry: { artifact_id: nil })
        .where.not(id: except_artifact_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_migrated_local(except_artifact_ids:)
      fdw_all.joins("INNER JOIN job_artifact_registry ON job_artifact_registry.artifact_id = #{fdw_table}.id")
        .with_files_stored_remotely
        .where.not(id: except_artifact_ids)
        .merge(Geo::JobArtifactRegistry.all)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_all
      if selective_sync?
        Geo::Fdw::Ci::JobArtifact.joins(:project).where(projects: { id: current_node.projects })
      else
        Geo::Fdw::Ci::JobArtifact.all
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def fdw_table
      Geo::Fdw::Ci::JobArtifact.table_name
    end

    #
    # Legacy accessors (non FDW)
    #

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_synced
      legacy_inner_join_registry_ids(
        syncable,
        find_synced_registries.pluck(:artifact_id),
        Ci::JobArtifact
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_failed
      legacy_inner_join_registry_ids(
        syncable,
        find_failed_registries.pluck(:artifact_id),
        Ci::JobArtifact
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_unsynced(except_artifact_ids:)
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck(:artifact_id) | except_artifact_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_migrated_local(except_artifact_ids:)
      registry_artifact_ids = Geo::JobArtifactRegistry.pluck(:artifact_id) - except_artifact_ids

      legacy_inner_join_registry_ids(
        all.with_files_stored_remotely,
        registry_artifact_ids,
        Ci::JobArtifact
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_synced_missing_on_primary
      legacy_inner_join_registry_ids(
        syncable,
        find_synced_missing_on_primary_registries.pluck(:artifact_id),
        Ci::JobArtifact
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
