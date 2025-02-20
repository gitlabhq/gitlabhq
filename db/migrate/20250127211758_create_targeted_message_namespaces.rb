# frozen_string_literal: true

class CreateTargetedMessageNamespaces < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :targeted_message_namespaces do |t|
      t.references :targeted_message, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :namespace_id, null: false

      t.timestamps_with_timezone null: false
    end

    add_index(
      :targeted_message_namespaces,
      [:targeted_message_id, :namespace_id],
      unique: true,
      name: 'index_targeted_message_namespaces_on_message_and_namespace'
    )
  end
end
