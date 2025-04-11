# frozen_string_literal: true

class CreateWorkItemCustomStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    # Factory: /ee/spec/factories/work_items/statuses/custom/statuses.rb
    create_table :work_item_custom_statuses do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :category, null: false, default: 1, limit: 1
      t.text :name, null: false, limit: 255
      t.text :description, limit: 255
      t.text :color, null: false, limit: 7

      t.index [:namespace_id, :name], unique: true
    end
  end
end
