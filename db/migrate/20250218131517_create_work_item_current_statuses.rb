# frozen_string_literal: true

class CreateWorkItemCurrentStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    # factory is in `ee/spec/factories/work_items/statuses/current_status.rb`
    create_table :work_item_current_statuses do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.references :namespace, null: false, foreign_key: { on_delete: :cascade }
      t.references :work_item, null: false, foreign_key: { to_table: :issues, on_delete: :cascade },
        index: { unique: true }
      t.bigint :system_defined_status_id, null: true
      # Should be references if model already existed, but we'll add this in a follow up MR.
      # We can already add it here so column order is correct.
      t.bigint :custom_status_id, null: true
      t.datetime_with_timezone :updated_at, null: false

      t.index [:work_item_id, :system_defined_status_id],
        name: 'idx_wi_current_statuses_on_wi_id_system_def_status_id_unique', unique: true
      t.index [:work_item_id, :custom_status_id],
        name: 'idx_wi_current_statuses_on_wi_id_custom_status_id_unique', unique: true
    end
  end
end
