# frozen_string_literal: true

class AddWorkItemDatesSourcesForeingKeys < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  TABLE = :work_item_dates_sources
  COLUMNS = {
    namespace_id: :namespaces,
    start_date_sourcing_work_item_id: :issues,
    start_date_sourcing_milestone_id: :milestones,
    due_date_sourcing_work_item_id: :issues,
    due_date_sourcing_milestone_id: :milestones
  }.freeze

  def up
    COLUMNS.each do |column, target_table|
      add_concurrent_foreign_key TABLE, target_table, column: column, on_delete: :nullify
      add_concurrent_index TABLE, column, name: "wi_datessources_#{column}_index"
    end
  end

  def down
    COLUMNS.each_key do |column|
      remove_foreign_key_if_exists TABLE, :issues, column: column
    end
  end
end
