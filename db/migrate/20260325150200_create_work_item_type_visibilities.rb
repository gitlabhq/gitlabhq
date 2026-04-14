# frozen_string_literal: true

class CreateWorkItemTypeVisibilities < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    create_table :work_item_type_visibilities do |t| # rubocop:disable Migration/EnsureFactoryForTable -- ee/spec/factories/work_items/types_framework/visibilities.rb
      t.bigint :namespace_id, null: false
      t.bigint :work_item_type_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :enabled, null: false, default: true
      t.boolean :propagate, null: false, default: false

      t.index [:namespace_id, :work_item_type_id],
        unique: true,
        name: 'uniq_wi_type_visibilities_on_namespace_and_type'
      t.index :work_item_type_id,
        name: 'index_work_item_type_visibilities_on_work_item_type_id'
    end
  end
end
