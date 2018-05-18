class CreateProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return if table_exists?(:project_mirror_data)

    create_table :project_mirror_data do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.string :status
      t.string :jid
      t.text :last_error
    end
  end

  def down
    drop_table(:project_mirror_data) if table_exists?(:project_mirror_data)
  end
end
