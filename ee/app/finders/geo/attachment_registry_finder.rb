module Geo
  class AttachmentRegistryFinder < FileRegistryFinder
    def attachments
      if selective_sync?
        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
    end

    def local_attachments
      attachments.with_files_stored_locally
    end

    def count_local_attachments
      local_attachments.count
    end

    def count_synced_attachments
      if aggregate_pushdown_supported?
        find_synced_attachments.count
      else
        legacy_find_synced_attachments.count
      end
    end

    def count_failed_attachments
      if aggregate_pushdown_supported?
        find_failed_attachments.count
      else
        legacy_find_failed_attachments.count
      end
    end

    def count_registry_attachments
      Geo::FileRegistry.attachments.count
    end

    def find_synced_attachments
      if use_legacy_queries?
        legacy_find_synced_attachments
      else
        fdw_find_synced_attachments
      end
    end

    def find_failed_attachments
      if use_legacy_queries?
        legacy_find_failed_attachments
      else
        fdw_find_failed_attachments
      end
    end

    # Find limited amount of non replicated attachments.
    #
    # You can pass a list with `except_file_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_file_ids ids that will be ignored from the query
    def find_unsynced_attachments(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_attachments(except_file_ids: except_file_ids)
        else
          fdw_find_unsynced_attachments(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end

    def find_migrated_local_attachments(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local_attachments(except_file_ids: except_file_ids)
        else
          fdw_find_migrated_local_attachments(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end

    def find_failed_attachments_registries
      Geo::FileRegistry.attachments.failed
    end

    def find_synced_missing_on_primary_attachments_registries
      Geo::FileRegistry.attachments.synced.missing_on_primary
    end

    private

    def group_uploads
      namespace_ids =
        if current_node.selective_sync_by_namespaces?
          Gitlab::GroupHierarchy.new(current_node.namespaces).base_and_descendants.select(:id)
        elsif current_node.selective_sync_by_shards?
          leaf_groups = Namespace.where(id: current_node.projects.select(:namespace_id))
          Gitlab::GroupHierarchy.new(leaf_groups).base_and_ancestors.select(:id)
        else
          Namespace.none
        end

      arel_namespace_ids = Arel::Nodes::SqlLiteral.new(namespace_ids.to_sql)

      upload_table[:model_type].eq('Namespace').and(upload_table[:model_id].in(arel_namespace_ids))
    end

    def project_uploads
      project_ids = current_node.projects.select(:id)
      arel_project_ids = Arel::Nodes::SqlLiteral.new(project_ids.to_sql)

      upload_table[:model_type].eq('Project').and(upload_table[:model_id].in(arel_project_ids))
    end

    def other_uploads
      upload_table[:model_type].not_in(%w[Namespace Project])
    end

    def upload_table
      Upload.arel_table
    end

    #
    # FDW accessors
    #

    def fdw_find_synced_attachments
      fdw_find_local_attachments.merge(Geo::FileRegistry.synced)
    end

    def fdw_find_failed_attachments
      fdw_find_local_attachments.merge(Geo::FileRegistry.failed)
    end

    def fdw_find_local_attachments
      fdw_attachments.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_attachments_table}.id")
        .with_files_stored_locally
        .merge(Geo::FileRegistry.attachments)
    end

    def fdw_find_unsynced_attachments(except_file_ids:)
      upload_types = Geo::FileService::DEFAULT_OBJECT_TYPES.map { |val| "'#{val}'" }.join(',')

      fdw_attachments.joins("LEFT OUTER JOIN file_registry
                                          ON file_registry.file_id = #{fdw_attachments_table}.id
                                         AND file_registry.file_type IN (#{upload_types})")
        .with_files_stored_locally
        .where(file_registry: { id: nil })
        .where.not(id: except_file_ids)
    end

    def fdw_attachments
      if selective_sync?
        Geo::Fdw::Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Geo::Fdw::Upload.all
      end
    end

    def fdw_attachments_table
      Geo::Fdw::Upload.table_name
    end

    def fdw_find_migrated_local_attachments(except_file_ids:)
      fdw_attachments.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_attachments_table}.id")
        .with_files_stored_remotely
        .merge(Geo::FileRegistry.attachments)
        .where.not(id: except_file_ids)
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_attachments
      legacy_inner_join_registry_ids(
        local_attachments,
        Geo::FileRegistry.attachments.synced.pluck(:file_id),
        Upload
      )
    end

    def legacy_find_failed_attachments
      legacy_inner_join_registry_ids(
        local_attachments,
        find_failed_attachments_registries.pluck(:file_id),
        Upload
      )
    end

    def legacy_find_unsynced_attachments(except_file_ids:)
      registry_file_ids = legacy_pluck_registry_file_ids(file_types: Geo::FileService::DEFAULT_OBJECT_TYPES) | except_file_ids

      legacy_left_outer_join_registry_ids(
        local_attachments,
        registry_file_ids,
        Upload
      )
    end

    def legacy_find_migrated_local_attachments(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.attachments.pluck(:file_id) - except_file_ids

      legacy_inner_join_registry_ids(
        attachments.with_files_stored_remotely,
        registry_file_ids,
        Upload
      )
    end
  end
end
