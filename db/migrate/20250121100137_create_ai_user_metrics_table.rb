# frozen_string_literal: true

class CreateAiUserMetricsTable < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    create_table :ai_user_metrics, id: false do |t|
      t.belongs_to :user, primary_key: true, null: false, index: false,
        foreign_key: { to_table: :users, on_delete: :cascade }
      t.date :last_duo_activity_on, null: false
    end

    drop_sequence(:ai_user_metrics, :user_id, "ai_user_metrics_user_id_seq")
  end

  def down
    drop_table :ai_user_metrics
  end
end
