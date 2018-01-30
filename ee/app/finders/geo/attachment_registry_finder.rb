module Geo
  class AttachmentRegistryFinder < FileRegistryFinder
    def attachments
      if selective_sync?
        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
    end

    def count_attachments
      attachments.count
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
    # You can pass a list with `except_registry_ids:` so you can exclude items you
    # already scheduled but haven't finished and persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_registry_ids ids that will be ignored from the query
    def find_unsynced_attachments(batch_size:, except_registry_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_attachments(except_registry_ids: except_registry_ids)
        else
          fdw_find_unsynced_attachments(except_registry_ids: except_registry_ids)
        end

      relation.limit(batch_size)
    end

    private

    def group_uploads
      namespace_ids = Gitlab::GroupHierarchy.new(current_node.namespaces).base_and_descendants.select(:id)
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
      fdw_find_attachments.merge(Geo::FileRegistry.synced)
    end

    def fdw_find_failed_attachments
      fdw_find_attachments.merge(Geo::FileRegistry.failed)
    end

    def fdw_find_attachments
      fdw_table = Geo::Fdw::Upload.table_name

      Geo::Fdw::Upload.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .merge(Geo::FileRegistry.attachments)
    end

    def fdw_find_unsynced_attachments(except_registry_ids:)
      fdw_table = Geo::Fdw::Upload.table_name
      upload_types = Geo::FileService::DEFAULT_OBJECT_TYPES.map { |val| "'#{val}'" }.join(',')

      Geo::Fdw::Upload.joins("LEFT OUTER JOIN file_registry
                                           ON file_registry.file_id = #{fdw_table}.id
                                          AND file_registry.file_type IN (#{upload_types})")
        .where(file_registry: { id: nil })
        .where.not(id: except_registry_ids)
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_attachments
      legacy_inner_join_registry_ids(
        attachments,
        Geo::FileRegistry.attachments.synced.pluck(:file_id),
        Upload
      )
    end

    def legacy_find_failed_attachments
      legacy_inner_join_registry_ids(
        attachments,
        Geo::FileRegistry.attachments.failed.pluck(:file_id),
        Upload
      )
    end

    def legacy_find_unsynced_attachments(except_registry_ids:)
      registry_ids = legacy_pluck_registry_ids(file_types: Geo::FileService::DEFAULT_OBJECT_TYPES, except_registry_ids: except_registry_ids)

      legacy_left_outer_join_registry_ids(
        attachments,
        registry_ids,
        Upload
      )
    end
  end
end
