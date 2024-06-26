# frozen_string_literal: true

class AddNotNullConstraintToNamespacesGitlabSusbcriptionHistories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    add_not_null_constraint :gitlab_subscription_histories, :namespace_id
  end

  def down
    remove_not_null_constraint :gitlab_subscription_histories, :namespace_id
  end
end
