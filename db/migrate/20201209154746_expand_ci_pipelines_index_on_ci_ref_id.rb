# frozen_string_literal: true

class ExpandCiPipelinesIndexOnCiRefId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_NAME = 'index_ci_pipelines_on_ci_ref_id_and_more'
  OLD_NAME = 'index_ci_pipelines_on_ci_ref_id'

  def up
    add_concurrent_index :ci_pipelines, %i[ci_ref_id id source status], order: { id: :desc }, where: 'ci_ref_id IS NOT NULL', name: NEW_NAME

    remove_concurrent_index_by_name :ci_pipelines, OLD_NAME
  end

  def down
    add_concurrent_index :ci_pipelines, :ci_ref_id, where: 'ci_ref_id IS NOT NULL', name: OLD_NAME

    remove_concurrent_index_by_name :ci_pipelines, NEW_NAME
  end
end
