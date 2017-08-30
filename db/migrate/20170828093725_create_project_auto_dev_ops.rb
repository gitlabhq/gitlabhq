class CreateProjectAutoDevOps < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :project_auto_devops do |t|
      t.belongs_to :project, index: true
      t.boolean :enabled, default: nil, null: true
      t.string :domain
    end

    add_timestamps_with_timezone(:project_auto_devops, null: false)

    # No need to check for violations as its a new table
    add_concurrent_foreign_key(:project_auto_devops, :projects, column: :project_id)
  end

  def down
    drop_table(:project_auto_devops)
  end
end
