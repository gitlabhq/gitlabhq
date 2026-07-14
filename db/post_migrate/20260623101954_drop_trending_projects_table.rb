# frozen_string_literal: true

class DropTrendingProjectsTable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :trending_projects, :projects,
        column: :project_id, name: :fk_rails_09feecd872, reverse_lock_order: true
    end

    drop_table :trending_projects, if_exists: true
  end

  def down
    return if table_exists?(:trending_projects)

    create_table :trending_projects do |t|
      t.bigint :project_id, null: false
    end

    add_concurrent_index :trending_projects, :project_id, unique: true,
      name: :index_trending_projects_on_project_id
    add_concurrent_foreign_key :trending_projects, :projects,
      column: :project_id, on_delete: :cascade, name: :fk_rails_09feecd872
  end
end
