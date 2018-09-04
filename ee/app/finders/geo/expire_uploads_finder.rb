module Geo
  class ExpireUploadsFinder
    def find_project_uploads(project)
      if Gitlab::Geo::Fdw.enabled?
        fdw_find_project_uploads(project)
      else
        legacy_find_project_uploads(project)
      end
    end

    def find_file_registries_uploads(project)
      if Gitlab::Geo::Fdw.enabled?
        fdw_find_file_registries_uploads(project)
      else
        legacy_find_file_registries_uploads(project)
      end
    end

    #
    # FDW accessors
    #

    # @return [ActiveRecord::Relation<Geo::Fdw::Upload>]
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_project_uploads(project)
      fdw_table = Geo::Fdw::Upload.table_name
      upload_type = 'file'

      Geo::Fdw::Upload.joins("JOIN file_registry
                                ON file_registry.file_id = #{fdw_table}.id
                               AND #{fdw_table}.model_id='#{project.id}'
                               AND #{fdw_table}.model_type='#{project.class.name}'
                               AND file_registry.file_type='#{upload_type}'")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::FileRegistry>]
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_file_registries_uploads(project)
      fdw_table = Geo::Fdw::Upload.table_name
      upload_type = 'file'

      Geo::FileRegistry.joins("JOIN #{fdw_table}
                                 ON file_registry.file_id = #{fdw_table}.id
                                AND #{fdw_table}.model_id='#{project.id}'
                                AND #{fdw_table}.model_type='#{project.class.name}'
                                AND file_registry.file_type='#{upload_type}'")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    #
    # Legacy accessors (non FDW)
    #

    # @return [ActiveRecord::Relation<Geo::FileRegistry>] list of file registry items
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_file_registries_uploads(project)
      upload_ids = Upload.where(model_type: project.class.name, model_id: project.id).pluck(:id)

      return Geo::FileRegistry.none if upload_ids.empty?

      values_sql = upload_ids.map { |id| "(#{id})" }.join(',')
      upload_type = 'file'

      Geo::FileRegistry.joins(<<~SQL)
        JOIN (VALUES #{values_sql})
          AS uploads (id)
          ON uploads.id = file_registry.file_id
         AND file_registry.file_type='#{upload_type}'
      SQL
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Upload>] list of upload files
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_project_uploads(project)
      file_registry_ids = legacy_find_file_registries_uploads(project).pluck(:file_id)

      return Upload.none if file_registry_ids.empty?

      values_sql = file_registry_ids.map { |f_id| "(#{f_id})" }.join(',')

      Upload.joins(<<~SQL)
        JOIN (VALUES #{values_sql})
          AS file_registry (file_id)
          ON (file_registry.file_id = uploads.id)
      SQL
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
