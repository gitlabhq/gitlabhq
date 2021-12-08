# frozen_string_literal: true

class AddCiRunnersIndexOnCreatedAtWhereActiveIsFalse < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_ci_runners_on_created_at_and_id_where_inactive'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, [:created_at, :id], where: 'active = FALSE', order: { created_at: :desc, id: :desc }, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end
end
