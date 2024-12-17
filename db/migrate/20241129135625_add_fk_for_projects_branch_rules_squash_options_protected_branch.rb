# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddFkForProjectsBranchRulesSquashOptionsProtectedBranch < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def up
    add_concurrent_foreign_key(
      :projects_branch_rules_squash_options,
      :protected_branches, column: :protected_branch_id,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key :projects_branch_rules_squash_options, column: :protected_branch_id, if_exists: true
    end
  end
end
