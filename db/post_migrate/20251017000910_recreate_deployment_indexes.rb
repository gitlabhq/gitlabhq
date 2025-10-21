# frozen_string_literal: true

class RecreateDeploymentIndexes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  def up
    return if Gitlab.com_except_jh?

    # rubocop:disable Migration/PreventIndexCreation -- These indexes should exist for self-managed.
    add_concurrent_index :deployments, :created_at, name: :index_deployments_on_created_at, if_not_exists: true
    add_concurrent_index :deployments, %i[id status created_at],
      name: :index_deployments_on_id_and_status_and_created_at, if_not_exists: true
    add_concurrent_index :deployments, %i[user_id status created_at],
      name: :index_deployments_on_user_id_and_status_and_created_at, if_not_exists: true
    add_concurrent_index :events, %i[project_id target_type action created_at author_id id],
      name: :index_on_events_to_improve_contribution_analytics_performance, if_not_exists: true
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down; end
end
