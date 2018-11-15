# frozen_string_literal: true

class AddPartialIndexForLegacySuccessfulDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'partial_index_deployments_for_legacy_successful_deployments'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index(:deployments, :id, where: "finished_at IS NULL AND status = 2", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:deployments, INDEX_NAME)
  end
end
