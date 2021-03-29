# frozen_string_literal: true

class ValidateNotNullConstraintOnGitlabSubscriptionsNamespaceId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :gitlab_subscriptions, :namespace_id
  end

  def down
    # no-op
  end
end
