class AddPipelineEventsToWebHooks < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:web_hooks, :pipeline_events, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:web_hooks, :pipeline_events)
  end
end
