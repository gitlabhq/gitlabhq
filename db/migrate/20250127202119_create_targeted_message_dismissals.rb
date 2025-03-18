# frozen_string_literal: true

class CreateTargetedMessageDismissals < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :targeted_message_dismissals do |t|
      t.references :targeted_message, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :user_id, null: false
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
    end

    add_index(
      :targeted_message_dismissals,
      [:targeted_message_id, :user_id, :namespace_id],
      unique: true, name: 'index_targeted_message_dismissals_on_message_user_in_namespace'
    )
  end
end
