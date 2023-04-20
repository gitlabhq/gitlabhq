# frozen_string_literal: true

class CreateAbuseTrustScores < Gitlab::Database::Migration[2.1]
  def change
    create_table :abuse_trust_scores do |t|
      t.belongs_to :user, foreign_key: { to_table: :users, on_delete: :cascade }, index: false

      t.float :score, null: false
      t.timestamps_with_timezone null: false
      t.integer :source, limit: 2, null: false
      t.text :correlation_id_value, limit: 32

      t.index [:user_id, :source, :created_at]
    end
  end
end
