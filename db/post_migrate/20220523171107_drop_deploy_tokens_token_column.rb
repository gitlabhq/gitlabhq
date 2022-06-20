# frozen_string_literal: true

class DropDeployTokensTokenColumn < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  COMPOSITE_INDEX_NAME = 'index_deploy_tokens_on_token_and_expires_at_and_id'

  def up
    remove_column :deploy_tokens, :token
  end

  def down
    unless column_exists?(:deploy_tokens, :token)
      add_column :deploy_tokens, :token, :string
    end

    add_concurrent_index(:deploy_tokens, :token, unique: true)
    add_concurrent_index(:deploy_tokens, %i[token expires_at id], where: 'revoked IS FALSE', name: COMPOSITE_INDEX_NAME)
  end
end
