# frozen_string_literal: true

class AddIndexOnExternalKeyToIssuesTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:issues, [:project_id, :external_key], unique: true, where: 'external_key IS NOT NULL')
  end

  def down
    remove_concurrent_index(:issues, [:project_id, :external_key])
  end
end
