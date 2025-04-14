# frozen_string_literal: true

class CreateWorkItemCustomLifecycles < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    # Factory: /ee/spec/factories/work_items/statuses/custom/lifecycles.rb
    create_table :work_item_custom_lifecycles do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.bigint :namespace_id, null: false
      t.bigint :default_open_status_id, null: false,
        index: { name: 'idx_wi_custom_lifecycles_on_open_status_id' }
      t.bigint :default_closed_status_id, null: false,
        index: { name: 'idx_wi_custom_lifecycles_on_closed_status_id' }
      t.bigint :default_duplicate_status_id, null: false,
        index: { name: 'idx_wi_custom_lifecycles_on_duplicate_status_id' }
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255

      t.index [:namespace_id, :name], unique: true
    end
  end
end
