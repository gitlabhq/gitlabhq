class AddUniqueConstraintToProjectMirrorDataProjectIdIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:project_mirror_data,
                         :project_id,
                         unique: true,
                         name: 'index_project_mirror_data_on_project_id_unique')

    remove_concurrent_index_by_name(:project_mirror_data, 'index_project_mirror_data_on_project_id')

    rename_index(:project_mirror_data,
                 'index_project_mirror_data_on_project_id_unique',
                 'index_project_mirror_data_on_project_id')
  end

  def down
    rename_index(:project_mirror_data,
                 'index_project_mirror_data_on_project_id',
                 'index_project_mirror_data_on_project_id_old')

    add_concurrent_index(:project_mirror_data, :project_id)

    remove_concurrent_index_by_name(:project_mirror_data,
                                    'index_project_mirror_data_on_project_id_old')
  end
end
