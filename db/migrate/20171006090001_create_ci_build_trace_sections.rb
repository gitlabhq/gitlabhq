class CreateCiBuildTraceSections < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_build_trace_sections do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :date_start, null: false
      t.datetime_with_timezone :date_end, null: false
      t.integer :byte_start, limit: 8, null: false
      t.integer :byte_end, limit: 8, null: false
      t.integer :build_id, null: false
      t.integer :section_name_id, null: false
    end

    add_index :ci_build_trace_sections, [:build_id, :section_name_id], unique: true
  end
end
