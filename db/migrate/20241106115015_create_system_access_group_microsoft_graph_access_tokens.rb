# frozen_string_literal: true

class CreateSystemAccessGroupMicrosoftGraphAccessTokens < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def change
    create_table :system_access_group_microsoft_graph_access_tokens do |t|
      t.timestamps_with_timezone null: false
      t.references :system_access_group_microsoft_application,
        index: { name: 'unique_index_group_ms_access_tokens_on_ms_app_id', unique: true }
      t.references :group, index: { name: 'index_group_id_on_group_microsoft_access_tokens' }, null: false
      t.bigint :temp_source_id, index: { unique: true, name: 'index_source_id_microsoft_access_tokens' },
        comment: 'Temporary column to store graph access tokens id'

      t.integer :expires_in, null: false
      t.binary :encrypted_token, null: false
      t.binary :encrypted_token_iv, null: false
    end
  end
end
