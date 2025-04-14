# frozen_string_literal: true

class CreateWorkItemCustomLifecycleStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    # Factory: /ee/spec/factories/work_items/statuses/custom/lifecycle_statuses.rb
    create_table :work_item_custom_lifecycle_statuses do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.bigint :namespace_id, null: false, index: { name: 'idx_wi_custom_lifecycle_statuses_on_namespace_id' }
      t.bigint :lifecycle_id, null: false
      t.bigint :status_id, null: false, index: { name: 'idx_wi_custom_lifecycle_statuses_on_status_id' }
      t.timestamps_with_timezone null: false
      t.integer :position, null: false, default: 0

      t.index [:lifecycle_id, :status_id], unique: true, name: 'idx_lifecycle_statuses_on_lifecycle_and_status'
    end
  end
end
