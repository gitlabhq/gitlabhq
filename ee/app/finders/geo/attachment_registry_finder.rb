module Geo
  class AttachmentRegistryFinder < RegistryFinder
    def count_attachments
      uploads.count
    end

    def count_synced_attachments
      find_synced_attachments.count
    end

    def count_failed_attachments
      find_failed_attachments.count
    end

    def find_synced_attachments
      relation =
        if use_legacy_queries?
          legacy_find_synced_attachments
        else
          fdw_find_synced_attachments
        end

      relation
    end

    def find_failed_attachments
      relation =
        if use_legacy_queries?
          legacy_find_failed_attachments
        else
          fdw_find_failed_attachments
        end

      relation
    end

    def uploads
      if selective_sync?
        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
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

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_attachments
      legacy_find_attachments(Geo::FileRegistry.attachments.synced.pluck(:file_id))
    end

    def legacy_find_failed_attachments
      legacy_find_attachments(Geo::FileRegistry.attachments.failed.pluck(:file_id))
    end

    def legacy_find_attachments(registry_file_ids)
      return Upload.none if registry_file_ids.empty?

      joined_relation = uploads.joins(<<~SQL)
        INNER JOIN
        (VALUES #{registry_file_ids.map { |id| "(#{id})" }.join(',')})
        file_registry(file_id)
        ON #{Upload.table_name}.id = file_registry.file_id
      SQL

      joined_relation
    end
  end
end
