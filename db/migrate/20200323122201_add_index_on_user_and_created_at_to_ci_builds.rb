# frozen_string_literal: true

class AddIndexOnUserAndCreatedAtToCiBuilds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_on_user_id_and_created_at_and_type_eq_ci_build'

  def up
    add_concurrent_index :ci_builds, [:user_id, :created_at], where: "type = 'Ci::Build'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
