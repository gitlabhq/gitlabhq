# frozen_string_literal: true

class CleanupClusterTokensWithNullName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 1000

  disable_ddl_transaction!

  class AgentToken < ActiveRecord::Base
    include EachBatch

    self.table_name = 'cluster_agent_tokens'
  end

  def up
    AgentToken.each_batch(of: BATCH_SIZE) do |relation|
      relation.where(name: nil).update_all("name = 'agent-token-' || id")
    end
  end

  def down
    # no-op : can't go back to `NULL` without first dropping the `NOT NULL` constraint
  end
end
