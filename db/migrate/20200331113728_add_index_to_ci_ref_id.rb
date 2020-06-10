# frozen_string_literal: true

class AddIndexToCiRefId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:ci_ref_id], where: 'ci_ref_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :ci_pipelines, [:ci_ref_id], where: 'ci_ref_id IS NOT NULL'
  end
end
