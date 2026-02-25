# frozen_string_literal: true

class AddDeletionScheduledAtToNamespaceDetails < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_namespace_details ADD COLUMN deletion_scheduled_at Nullable(DateTime64(6, 'UTC'))
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_namespace_details DROP COLUMN deletion_scheduled_at;
    SQL
  end
end
