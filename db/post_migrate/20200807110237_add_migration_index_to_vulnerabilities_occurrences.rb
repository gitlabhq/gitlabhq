# frozen_string_literal: true

class AddMigrationIndexToVulnerabilitiesOccurrences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerability_occurrences,
      "project_id, report_type, encode(project_fingerprint, 'hex'::text)",
      name: 'index_vulnerability_occurrences_for_issue_links_migration'
  end

  def down
    remove_concurrent_index_by_name :vulnerability_occurrences,
      :index_vulnerability_occurrences_for_issue_links_migration
  end
end
