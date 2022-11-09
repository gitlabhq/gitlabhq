# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ChangeMemberNamespaceIdNotNull < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :members, :member_namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :members, :member_namespace_id
  end
end
