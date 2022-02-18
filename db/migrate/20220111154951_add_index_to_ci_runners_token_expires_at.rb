# frozen_string_literal: true

class AddIndexToCiRunnersTokenExpiresAt < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, [:token_expires_at, :id], order: { token_expires_at: :asc, id: :desc }, name: 'index_ci_runners_on_token_expires_at_and_id_desc'
    add_concurrent_index :ci_runners, [:token_expires_at, :id], order: { token_expires_at: :desc, id: :desc }, name: 'index_ci_runners_on_token_expires_at_desc_and_id_desc'
  end

  def down
    remove_concurrent_index_by_name :ci_runners, 'index_ci_runners_on_token_expires_at_desc_and_id_desc'
    remove_concurrent_index_by_name :ci_runners, 'index_ci_runners_on_token_expires_at_and_id_desc'
  end
end
