# frozen_string_literal: true

class CreateIndexOnEnvironmentsAutoDeleteAt < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_on_state_and_auto_delete_at'

  def up
    add_concurrent_index :environments,
      %i[auto_delete_at],
      where: "auto_delete_at IS NOT NULL AND state = 'stopped'",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end
end
