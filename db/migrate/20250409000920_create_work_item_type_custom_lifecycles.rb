# frozen_string_literal: true

class CreateWorkItemTypeCustomLifecycles < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    # Factory: /ee/spec/factories/work_items/type_custom_lifecycles.rb
    create_table :work_item_type_custom_lifecycles do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.bigint :namespace_id, null: false
      t.bigint :work_item_type_id, null: false, index: { name: 'idx_wi_type_custom_lifecycles_on_work_item_type_id' }
      t.bigint :lifecycle_id, null: false, index: { name: 'idx_wi_type_custom_lifecycles_on_lifecycle_id' }
      t.timestamps_with_timezone null: false

      t.index [:namespace_id, :work_item_type_id, :lifecycle_id],
        name: 'idx_wi_type_custom_lifecycles_on_namespace_type_lifecycle', unique: true
    end
  end
end
