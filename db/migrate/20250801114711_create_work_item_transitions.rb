# frozen_string_literal: true

class CreateWorkItemTransitions < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    # factory is in `spec/factories/work_items/transition.rb`
    create_table :work_item_transitions, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.bigint :work_item_id, primary_key: true, default: nil
      t.bigint :namespace_id, null: false
      t.bigint :moved_to_id, null: true
      t.bigint :duplicated_to_id, null: true
      t.bigint :promoted_to_epic_id, null: true

      t.index :namespace_id, name: 'index_work_item_transitions_on_namespace_id'
      t.index :moved_to_id,
        where: 'moved_to_id IS NOT NULL',
        name: 'index_work_item_transitions_on_moved_to_id'
      t.index :duplicated_to_id,
        where: 'duplicated_to_id IS NOT NULL',
        name: 'index_work_item_transitions_on_duplicated_to_id'
      t.index :promoted_to_epic_id,
        where: 'promoted_to_epic_id IS NOT NULL',
        name: 'index_work_item_transitions_on_promoted_to_epic_id'
    end
  end

  def down
    drop_table :work_item_transitions
  end
end
