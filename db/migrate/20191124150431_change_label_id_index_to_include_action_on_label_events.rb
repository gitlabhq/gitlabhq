# frozen_string_literal: true

class ChangeLabelIdIndexToIncludeActionOnLabelEvents < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:resource_label_events, %I[label_id action])

    remove_concurrent_index(:resource_label_events, :label_id)
  end

  def down
    add_concurrent_index(:resource_label_events, :label_id)

    remove_concurrent_index(:resource_label_events, %I[label_id action])
  end
end
