# frozen_string_literal: true

class AddIndexOnVulnerabilitiesStateCase < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_vulnerabilities_on_state_case_id'
  STATE_ORDER_ARRAY_POSITION = 'ARRAY_POSITION(ARRAY[1, 4, 3, 2]::smallint[], state)'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, "#{STATE_ORDER_ARRAY_POSITION}, id DESC", name: INDEX_NAME
    add_concurrent_index :vulnerabilities, "#{STATE_ORDER_ARRAY_POSITION} DESC, id DESC", name: "#{INDEX_NAME}_desc"
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, "#{INDEX_NAME}_desc"
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end
