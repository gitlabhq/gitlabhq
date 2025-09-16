# frozen_string_literal: true

class CreateWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    # Factory exists at spec/factories/work_items/statuses/custom/mappings.rb
    create_table :work_item_custom_status_mappings do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      # Order doesn't matter because both bigint and datetime are 8 bytes
      t.bigint :namespace_id, null: false
      t.bigint :old_status_id, null: false
      t.bigint :new_status_id, null: false
      t.bigint :work_item_type_id, null: false
      t.datetime_with_timezone :valid_from, null: true
      t.datetime_with_timezone :valid_until, null: true

      t.timestamps_with_timezone null: false
    end
  end
end
