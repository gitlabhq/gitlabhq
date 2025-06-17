# frozen_string_literal: true

class AddCreatedByIdToCustomStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :work_item_custom_statuses, :created_by_id, :bigint
  end
end
