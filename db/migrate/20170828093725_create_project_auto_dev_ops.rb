class CreateProjectAutoDevOps < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :project_auto_devops do |t|
      t.belongs_to :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.boolean :enabled, default: nil, null: true
      t.string :domain
    end
  end

  def down
    drop_table(:project_auto_devops)
  end
end
