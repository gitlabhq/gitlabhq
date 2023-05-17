# frozen_string_literal: true

class DeleteSecurityPolicyBotUsers < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class User < MigrationRecord
    self.table_name = 'users'

    enum user_type: { security_policy_bot: 10 }
  end

  def up
    User.where(user_type: :security_policy_bot).delete_all
  end

  def down
    # no-op

    # Deleted records can't be restored
  end
end
