# frozen_string_literal: true

class AddDetectedAtIdIndexToVulnerabilities < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_vulnerabilities_on_detected_at_and_id'

  def up
    add_concurrent_index :vulnerabilities, [:id, :detected_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end
