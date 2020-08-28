# frozen_string_literal: true

class AddIndexOnEndDateAndNamespaceIdToGitlabSubscriptions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :gitlab_subscriptions, [:end_date, :namespace_id]
  end

  def down
    remove_concurrent_index :gitlab_subscriptions, [:end_date, :namespace_id],
      name: 'index_gitlab_subscriptions_on_end_date_and_namespace_id'
  end
end
