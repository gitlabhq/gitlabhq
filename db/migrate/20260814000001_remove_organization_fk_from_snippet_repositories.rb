# frozen_string_literal: true

# snippet_repositories.snippet_organization_id is copied from snippets.organization_id,
# which itself has no hard FK to organizations (only a loose FK for async delete).
# A hard FK here causes PG::ForeignKeyViolation when a child row is written after the
# organization is deleted but before the snippet LFK cleanup runs.
# Cleanup still happens via the hard snippet_id -> snippets ON DELETE CASCADE FK.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/613747
class RemoveOrganizationFkFromSnippetRepositories < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_efaf4ac269'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :snippet_repositories, :organizations,
        column: :snippet_organization_id, name: CONSTRAINT_NAME
    end
  end

  # Rollback may fail if orphaned snippet_organization_id values have accumulated.
  # Delete orphans first if needed.
  def down
    add_concurrent_foreign_key :snippet_repositories, :organizations,
      column: :snippet_organization_id, on_delete: :cascade,
      name: CONSTRAINT_NAME, reverse_lock_order: true
  end
end
