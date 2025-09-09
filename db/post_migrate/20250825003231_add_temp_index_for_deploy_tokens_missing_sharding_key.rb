# frozen_string_literal: true

class AddTempIndexForDeployTokensMissingShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'tmp_index_deploy_tokens_on_id_where_project_and_group_null'

  def up
    add_concurrent_index :deploy_tokens, :id, where: 'project_id IS NULL AND group_id IS NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deploy_tokens, name: INDEX_NAME
  end
end
