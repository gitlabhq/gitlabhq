class SetMinimalProjectBuildTimeout < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MINIMUM_TIMEOUT = 600

  # Allow this migration to resume if it fails partway through
  disable_ddl_transaction!

  def up
    update_column_in_batches(:projects, :build_timeout, MINIMUM_TIMEOUT) do |table, query|
      query.where(table[:build_timeout].lt(MINIMUM_TIMEOUT))
    end
  end

  def down
    # no-op
  end
end
