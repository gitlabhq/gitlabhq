# frozen_string_literal: true

# The migration below has been removed due to discovery of a bug. The bug has been fixed and the migration
# has been rescheduled for execution in
#   db/post_migrate/20240711035245_queue_backfill_root_namespace_cluster_agent_mappings_again.rb

class QueueBackfillRootNamespaceClusterAgentMappings < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
