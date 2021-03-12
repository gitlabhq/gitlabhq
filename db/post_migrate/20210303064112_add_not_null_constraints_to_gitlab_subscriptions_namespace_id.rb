# frozen_string_literal: true

class AddNotNullConstraintsToGitlabSubscriptionsNamespaceId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This will add the `NOT NULL` constraint WITHOUT validating it
    add_not_null_constraint :gitlab_subscriptions, :namespace_id, validate: false
  end

  def down
    # Down is required as `add_not_null_constraint` is not reversible
    remove_not_null_constraint :gitlab_subscriptions, :namespace_id
  end
end
