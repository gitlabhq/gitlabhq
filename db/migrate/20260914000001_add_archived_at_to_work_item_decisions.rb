# frozen_string_literal: true

class AddArchivedAtToWorkItemDecisions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :work_item_decisions, :archived_at, :datetime_with_timezone
  end
end
