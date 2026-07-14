# frozen_string_literal: true

class QueueBackfillMcpServerEnabled < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    # no-op: superseded by QueueResyncMcpServerEnabled post-migration (milestone 19.2)
  end

  def down
    # no-op
  end
end
