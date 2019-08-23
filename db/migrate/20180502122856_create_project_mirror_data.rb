class CreateProjectMirrorData < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToStringColumns
  def up
    if table_exists?(:project_mirror_data)
      add_column :project_mirror_data, :status, :string unless column_exists?(:project_mirror_data, :status)
      add_column :project_mirror_data, :jid, :string unless column_exists?(:project_mirror_data, :jid)
      add_column :project_mirror_data, :last_error, :text unless column_exists?(:project_mirror_data, :last_error)
    else
      create_table :project_mirror_data do |t|
        t.references :project, index: true, foreign_key: { on_delete: :cascade }
        t.string :status
        t.string :jid
        t.text :last_error
      end
    end
  end
  # rubocop:enable Migration/AddLimitToStringColumns

  def down
    remove_column :project_mirror_data, :status
    remove_column :project_mirror_data, :jid
    remove_column :project_mirror_data, :last_error

    # ee/db/migrate/20170509153720_create_project_mirror_data_ee.rb will remove the table.
  end
end
