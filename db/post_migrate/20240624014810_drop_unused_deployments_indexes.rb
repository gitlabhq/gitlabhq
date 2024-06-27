# frozen_string_literal: true

class DropUnusedDeploymentsIndexes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  def up
    prepare_async_index_removal :deployments, :created_at,
      name: 'index_deployments_on_created_at'
    prepare_async_index_removal :deployments, %i[id status created_at],
      name: 'index_deployments_on_id_and_status_and_created_at'
    prepare_async_index_removal :deployments, %i[user_id status created_at],
      name: 'index_deployments_on_user_id_and_status_and_created_at'
  end

  def down
    unprepare_async_index :deployments, :created_at,
      name: 'index_deployments_on_created_at'
    unprepare_async_index :deployments, %i[id status created_at],
      name: 'index_deployments_on_id_and_status_and_created_at'
    unprepare_async_index :deployments, %i[user_id status created_at],
      name: 'index_deployments_on_user_id_and_status_and_created_at'
  end
end
