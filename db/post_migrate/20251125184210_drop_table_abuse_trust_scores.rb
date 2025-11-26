# frozen_string_literal: true

class DropTableAbuseTrustScores < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  disable_ddl_transaction!

  def up
    drop_table :abuse_trust_scores, if_exists: true
  end

  def down
    create_table :abuse_trust_scores, if_not_exists: true do |t|
      t.references :user, null: true, index: false
      t.float :score, null: false
      t.timestamps_with_timezone null: false
      t.integer :source, limit: 2, null: false
      t.text :correlation_id_value, limit: 255

      t.index [:user_id, :source, :created_at]
    end

    add_concurrent_foreign_key :abuse_trust_scores, :users, column: :user_id, on_delete: :cascade,
      name: 'fk_rails_b903079eb4'
  end
end
