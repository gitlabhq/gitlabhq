# frozen_string_literal: true

class AddCompoundIndexOnProjectIdAndIdForVulnerabilities < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_vulnerabilities_on_project_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :vulnerabilities, [:project_id, :id], name: INDEX_NAME
  end
end
