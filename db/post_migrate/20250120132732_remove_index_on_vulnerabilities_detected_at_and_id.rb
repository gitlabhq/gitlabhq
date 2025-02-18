# frozen_string_literal: true

class RemoveIndexOnVulnerabilitiesDetectedAtAndId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_vulnerabilities_on_detected_at_and_id'

  milestone '17.9'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :vulnerabilities, name: INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerabilities, [:id, :detected_at], name: INDEX_NAME
  end
end
