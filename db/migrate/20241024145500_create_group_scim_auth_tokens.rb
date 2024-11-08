# frozen_string_literal: true

class CreateGroupScimAuthTokens < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def change
    create_table :group_scim_auth_access_tokens do |t|
      t.references :group, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false, index: false
      t.timestamps_with_timezone null: false
      t.bigint :temp_source_id, index: { unique: true }, comment: 'Temporary column to store scim_tokens id'
      t.binary :token_encrypted, null: false

      t.index [:group_id, :token_encrypted],
        name: 'index_group_scim_access_tokens_on_group_id_and_token', unique: true
    end
  end
end
