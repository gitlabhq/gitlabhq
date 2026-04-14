# frozen_string_literal: true

class CreateWorkItemPositions < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    create_table :work_item_positions, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory in spec/factories/work_items/position.rb
      t.bigint :work_item_id, primary_key: true, default: nil
      t.bigint :namespace_id, null: false

      t.bigint :relative_position, null: true

      t.timestamps_with_timezone null: false

      t.index [:namespace_id, :relative_position]
    end
  end

  def down
    drop_table :work_item_positions
  end
end
