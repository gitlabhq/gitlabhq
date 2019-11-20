# frozen_string_literal: true

class AddIndexToEnvironmentsOnProjectIdStateEnvironmentType < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_environments_on_project_id_and_state'.freeze
  NEW_INDEX_NAME = 'index_environments_on_project_id_state_environment_type'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index(:environments, [:project_id, :state, :environment_type], name: NEW_INDEX_NAME)
    remove_concurrent_index_by_name(:environments, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:environments, [:project_id, :state], name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(:environments, NEW_INDEX_NAME)
  end
end
