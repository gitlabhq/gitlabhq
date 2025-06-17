# frozen_string_literal: true

class AddUpdatedByIdToCustomLifecycles < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :work_item_custom_lifecycles, :updated_by_id, :bigint
  end
end
