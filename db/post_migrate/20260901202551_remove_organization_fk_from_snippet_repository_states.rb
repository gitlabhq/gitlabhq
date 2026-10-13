# frozen_string_literal: true

# snippet_repository_states.snippet_organization_id is copied from snippet_repositories via
# trigger_decac6b7c511, which can hold a dangling org id after MR 250288 dropped the hard FK
# from snippet_repositories. The hard FK here then causes PG::ForeignKeyViolation on Geo primaries.
# Cleanup still happens via fk_5f750f3182 (snippet_repository_id -> snippet_repositories CASCADE).
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/626869
class RemoveOrganizationFkFromSnippetRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_634bc9f2e3'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :snippet_repository_states, :organizations,
        column: :snippet_organization_id, name: CONSTRAINT_NAME
    end
  end

  # add_concurrent_foreign_key validates the constraint, failing with
  # PG::ForeignKeyViolation if dangling organization ids exist. If rollback fails:
  # DELETE FROM snippet_repository_states WHERE snippet_organization_id IS NOT NULL
  # AND snippet_organization_id NOT IN (SELECT id FROM organizations);
  def down
    add_concurrent_foreign_key :snippet_repository_states, :organizations,
      column: :snippet_organization_id, on_delete: :cascade,
      name: CONSTRAINT_NAME, reverse_lock_order: true
  end
end
