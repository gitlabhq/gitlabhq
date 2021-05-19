# frozen_string_literal: true

class CopyAdoptionSnapshotNamespace < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
    UPDATE analytics_devops_adoption_snapshots snapshots
      SET namespace_id = segments.namespace_id
    FROM analytics_devops_adoption_segments segments
    WHERE snapshots.namespace_id IS NULL AND segments.id = snapshots.segment_id
    SQL
  end

  def down
    execute 'UPDATE analytics_devops_adoption_snapshots SET namespace_id = NULL'
  end
end
