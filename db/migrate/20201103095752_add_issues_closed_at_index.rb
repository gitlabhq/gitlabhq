# frozen_string_literal: true

class AddIssuesClosedAtIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:issues, [:project_id, :closed_at])
  end

  def down
    remove_concurrent_index_by_name(:issues, 'index_issues_on_project_id_and_closed_at')
  end
end
