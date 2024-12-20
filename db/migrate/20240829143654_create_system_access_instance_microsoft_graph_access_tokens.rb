# frozen_string_literal: true

class CreateSystemAccessInstanceMicrosoftGraphAccessTokens < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :system_access_instance_microsoft_graph_access_tokens do |t|
      t.timestamps_with_timezone null: false
      t.references :system_access_instance_microsoft_application,
        index: { name: 'unique_index_instance_ms_access_tokens_on_ms_app_id', unique: true },
        foreign_key: { on_delete: :cascade }
      t.integer :expires_in, null: false
      t.binary :encrypted_token, null: false
      t.binary :encrypted_token_iv, null: false
    end
  end
end
