# frozen_string_literal: true

class DropTableApprovers < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    drop_table :approvers, if_exists: true
  end

  def down
    create_table :approvers do |t|
      t.bigint :target_id, null: false
      t.string :target_type
      t.bigint :user_id, null: false

      # rubocop:disable Migration/Datetime -- Needs to match old table before removal
      t.datetime :created_at, precision: nil, null: true
      t.datetime :updated_at, precision: nil, null: true
      # rubocop:enable Migration/Datetime
    end

    add_index :approvers, [:target_id, :target_type],
      name: 'index_approvers_on_target_id_and_target_type'
    add_index :approvers, :user_id,
      name: 'index_approvers_on_user_id'
  end
end
