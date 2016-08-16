class AddPipelineEventsToServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:services, :pipeline_events, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:services, :pipeline_events)
  end
end
