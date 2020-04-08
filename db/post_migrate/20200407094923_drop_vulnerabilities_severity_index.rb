# frozen_string_literal: true

class DropVulnerabilitiesSeverityIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  INDEX_NAME = 'undefined_vulnerability'

  def up
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end

  def down
    add_concurrent_index(:vulnerabilities, :id, where: 'severity = 0', name: INDEX_NAME)
  end
end
