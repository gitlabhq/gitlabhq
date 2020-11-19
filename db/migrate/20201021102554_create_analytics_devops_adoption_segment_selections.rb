# frozen_string_literal: true

class CreateAnalyticsDevopsAdoptionSegmentSelections < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :analytics_devops_adoption_segment_selections do |t|
      t.references :segment, index: { name: 'index_on_segment_selections_segment_id' }, null: false, foreign_key: { to_table: :analytics_devops_adoption_segments, on_delete: :cascade }
      t.bigint :group_id
      t.bigint :project_id
      t.index [:group_id, :segment_id], unique: true, name: 'index_on_segment_selections_group_id_segment_id'
      t.index [:project_id, :segment_id], unique: true, name: 'index_on_segment_selections_project_id_segment_id'

      t.timestamps_with_timezone
    end
  end
end
