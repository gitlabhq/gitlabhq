# frozen_string_literal: true

class AddUpdatedByIdToCustomStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :work_item_custom_statuses, :updated_by_id, :bigint
  end
end
