# frozen_string_literal: true

class CreateSystemAccessMicrosoftGraphAccessTokens < Gitlab::Database::Migration[2.1]
  def change
    create_table :system_access_microsoft_graph_access_tokens do |t|
      t.timestamps_with_timezone null: false
      t.references :system_access_microsoft_application,
        index: { name: 'unique_index_sysaccess_ms_access_tokens_on_sysaccess_ms_app_id', unique: true },
        foreign_key: { on_delete: :cascade }
      t.integer :expires_in, null: false
      t.binary :encrypted_token, null: false
      t.binary :encrypted_token_iv, null: false
    end
  end
end
