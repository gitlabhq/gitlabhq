# frozen_string_literal: true

class AddWebHookIndexOnNilForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  INDEX_NAME = 'tmp_idx_all_foreign_keys_null'

  def up
    add_concurrent_index(
      :web_hooks,
      :id,
      where: "project_id IS NULL AND group_id IS NULL AND organization_id IS NULL AND integration_id IS NULL",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :web_hooks, INDEX_NAME
  end
end
