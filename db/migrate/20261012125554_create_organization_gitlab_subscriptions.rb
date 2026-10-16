# frozen_string_literal: true

class CreateOrganizationGitlabSubscriptions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.6'

  ORGANIZATION_INDEX_NAME = 'index_organization_gitlab_subscriptions_on_organization_id'
  GITLAB_SUBSCRIPTION_INDEX_NAME = 'idx_organization_gitlab_subscriptions_on_gitlab_subscription_id'

  def up
    create_table :organization_gitlab_subscriptions, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false
      t.bigint :organization_id, null: false
      t.bigint :gitlab_subscription_id, null: false

      t.index :organization_id, unique: true, name: ORGANIZATION_INDEX_NAME
      t.index :gitlab_subscription_id, unique: true, name: GITLAB_SUBSCRIPTION_INDEX_NAME
    end

    add_concurrent_foreign_key :organization_gitlab_subscriptions, :organizations,
      column: :organization_id, on_delete: :cascade
    add_concurrent_foreign_key :organization_gitlab_subscriptions, :gitlab_subscriptions,
      column: :gitlab_subscription_id, on_delete: :cascade
  end

  def down
    drop_table :organization_gitlab_subscriptions
  end
end
