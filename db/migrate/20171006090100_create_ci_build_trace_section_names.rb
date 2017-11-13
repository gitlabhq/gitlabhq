class CreateCiBuildTraceSectionNames < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :ci_build_trace_section_names do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
    end

    add_index :ci_build_trace_section_names, [:project_id, :name], unique: true
  end

  def down
    remove_foreign_key :ci_build_trace_section_names, column: :project_id
    drop_table :ci_build_trace_section_names
  end
end
