# frozen_string_literal: true

class MigrateDelayedProjectRemovalFromNamespacesToNamespaceSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    include ::EachBatch
  end

  def up
    Namespace.select(:id).where(delayed_project_removal: true).each_batch do |batch|
      values = batch.map { |record| "(#{record.id}, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" }

      execute <<-EOF.strip_heredoc
        INSERT INTO namespace_settings (namespace_id, delayed_project_removal, created_at, updated_at)
        VALUES #{values.join(', ')}
        ON CONFLICT (namespace_id) DO UPDATE
          SET delayed_project_removal = TRUE
      EOF
    end
  end

  def down
    # no-op
  end
end
