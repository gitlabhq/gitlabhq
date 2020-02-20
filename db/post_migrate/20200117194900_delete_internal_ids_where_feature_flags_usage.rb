# frozen_string_literal: true

class DeleteInternalIdsWhereFeatureFlagsUsage < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sql = <<~SQL
      DELETE FROM internal_ids WHERE usage = 6
    SQL

    execute(sql)
  end

  def down
    # no-op
  end
end
