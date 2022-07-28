# frozen_string_literal: true

class AddAuthorToCiSubscriptionsProjects < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_subscriptions_projects_author_id'

  def up
    unless column_exists?(:ci_subscriptions_projects, :author_id)
      add_column :ci_subscriptions_projects, :author_id, :bigint
    end

    add_concurrent_index :ci_subscriptions_projects, :author_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_subscriptions_projects, INDEX_NAME
    remove_column :ci_subscriptions_projects, :author_id
  end
end
