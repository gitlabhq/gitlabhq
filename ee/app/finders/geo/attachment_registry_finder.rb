module Geo
  class AttachmentRegistryFinder < RegistryFinder
    def find_synced_attachments(batch_size: nil)
      relation =
        if Gitlab::Geo.fdw?
          fdw_find_synced_attachments
        else
          legacy_find_synced_attachments
        end

      if batch_size
        relation.limit(batch_size)
      else
        relation
      end
    end

    def find_failed_attachments(batch_size: nil)
      relation =
        if Gitlab::Geo.fdw?
          fdw_find_failed_attachments
        else
          legacy_find_failed_attachments
        end

      if batch_size
        relation.limit(batch_size)
      else
        relation
      end
    end

    private

    def uploads
      upload_model = Gitlab::Geo.fdw? ? Geo::Fdw::Upload : Upload

      if selective_sync
        upload_table    = upload_model.arel_table
        group_uploads   = upload_table[:model_type].eq('Namespace').and(upload_table[:model_id].in(current_node.namespace_ids))
        project_uploads = upload_table[:model_type].eq('Project').and(upload_table[:model_id].in(current_node.restricted_project_ids))
        other_uploads   = upload_table[:model_type].not_in(%w[Namespace Project])

        upload_model.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        upload_model.all
      end
    end

    #
    # FDW accessors
    #

    def fdw_table
      Geo::Fdw::Upload.table_name
    end

    def fdw_find_synced_attachments
      uploads.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .merge(Geo::FileRegistry.attachments)
        .merge(Geo::FileRegistry.synced)
    end

    def fdw_find_failed_attachments
      uploads.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .merge(Geo::FileRegistry.attachments)
        .merge(Geo::FileRegistry.failed)
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
        ON uploads.id = file_registry.file_id
      SQL

      joined_relation
    end
  end
end
