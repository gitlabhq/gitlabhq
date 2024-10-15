# frozen_string_literal: true

class CreateWorkItemTypeCustomFields < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :work_item_type_custom_fields do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in `ee/spec/factories/work_items/type_custom_fields.rb`
      t.references :namespace, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.bigint :custom_field_id, null: false
      t.bigint :work_item_type_id, null: false
      t.timestamps_with_timezone null: false

      t.index :custom_field_id
      t.index :work_item_type_id

      t.index [:namespace_id, :work_item_type_id, :custom_field_id],
        name: 'idx_wi_type_custom_fields_on_ns_id_wi_type_id_custom_field_id', unique: true
    end
  end
end
