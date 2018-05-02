class CreateProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return if table_exists?(:project_mirror_data)

    create_table :project_mirror_data do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.string :status
      t.string :jid
      t.text :last_error
    end

    add_concurrent_index :project_mirror_data, :jid
    add_concurrent_index :project_mirror_data, :status
  end

  def down
    remove_index :project_mirror_data, :jid if index_exists? :project_mirror_data, :jid
    remove_index :project_mirror_data, :status if index_exists? :project_mirror_data, :status

    drop_table(:project_mirror_data) if table_exists?(:project_mirror_data)
  end
end
