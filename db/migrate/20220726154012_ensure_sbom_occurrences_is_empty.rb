# frozen_string_literal: true

class EnsureSbomOccurrencesIsEmpty < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Ensure that the sbom_occurrences table is empty to ensure that the
    # following migration adding a not-null column succeeds.
    # The code which creates records in this table has not been implemented yet.
    execute('DELETE FROM sbom_occurrences')
  end

  def down
    # no-op
  end
end
