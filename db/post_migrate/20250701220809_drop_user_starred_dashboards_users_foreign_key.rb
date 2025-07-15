# frozen_string_literal: true

class DropUserStarredDashboardsUsersForeignKey < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_bd6ae32fac'

  def up
    return unless table_exists?(:metrics_users_starred_dashboards)

    with_lock_retries do
      remove_foreign_key_if_exists(
        :metrics_users_starred_dashboards,
        column: :user_id,
        on_delete: :cascade,
        name: CONSTRAINT_NAME
      )
    end
  end

  def down
    return unless table_exists?(:metrics_users_starred_dashboards)

    add_concurrent_foreign_key(
      :metrics_users_starred_dashboards,
      :users,
      column: :user_id,
      on_delete: :cascade,
      name: CONSTRAINT_NAME
    )
  end
end
