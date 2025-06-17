# frozen_string_literal: true

class IndexCiRunnerTaggingsOnOrganizationId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  milestone '18.1'

  disable_ddl_transaction!

  TABLE_NAME = 'ci_runner_taggings'
  INDEX_NAME = "index_#{TABLE_NAME}_on_organization_id"

  def up
    add_concurrent_partitioned_index(TABLE_NAME, :organization_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
