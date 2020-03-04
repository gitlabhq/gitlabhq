# frozen_string_literal: true

class AddIndexForGroupAndIidSearchToEpics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_epics_on_group_id_and_iid_varchar_pattern'

  disable_ddl_transaction!

  def up
    disable_statement_timeout do
      execute "CREATE INDEX CONCURRENTLY \"#{INDEX_NAME}\" ON epics (group_id, CAST(iid AS VARCHAR) varchar_pattern_ops);"
    end
  end

  def down
    disable_statement_timeout do
      remove_concurrent_index_by_name :epics, INDEX_NAME
    end
  end
end
