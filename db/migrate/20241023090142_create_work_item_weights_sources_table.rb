# frozen_string_literal: true

class CreateWorkItemWeightsSourcesTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :work_item_weights_sources, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in ee/spec/factories/work_items/weights_sources.rb
      t.references :work_item,
        primary_key: true,
        default: nil,
        foreign_key: { on_delete: :cascade, to_table: :issues }
      t.bigint :namespace_id, null: false
      t.bigint :rolled_up_weight
      t.bigint :rolled_up_completed_weight
      t.timestamps_with_timezone null: false

      t.index :namespace_id
    end
  end
end
