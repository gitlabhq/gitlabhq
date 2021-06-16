# frozen_string_literal: true

class RemoveSegmentSelectionsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    drop_table :analytics_devops_adoption_segment_selections
  end

  def down
    create_table :analytics_devops_adoption_segment_selections do |t|
      t.references :segment, index: { name: 'index_on_segment_selections_segment_id' }, null: false, foreign_key: { to_table: :analytics_devops_adoption_segments, on_delete: :cascade }
      t.bigint :group_id
      t.bigint :project_id
      t.index [:group_id, :segment_id], unique: true, name: 'index_on_segment_selections_group_id_segment_id'
      t.index [:project_id, :segment_id], unique: true, name: 'index_on_segment_selections_project_id_segment_id'

      t.timestamps_with_timezone
    end
    add_concurrent_foreign_key(:analytics_devops_adoption_segment_selections, :projects, column: :project_id, on_delete: :cascade)
    add_concurrent_foreign_key(:analytics_devops_adoption_segment_selections, :namespaces, column: :group_id, on_delete: :cascade)
    add_check_constraint :analytics_devops_adoption_segment_selections, '(project_id != NULL AND group_id IS NULL) OR (group_id != NULL AND project_id IS NULL)', 'segment_selection_project_id_or_group_id_required'
  end
end
