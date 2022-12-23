# frozen_string_literal: true

class TruncateSbomOccurrences < Gitlab::Database::Migration[2.1]
  def up
    # Because existing data in the table violates the new
    # uniqueness constraints, we need to remove the non-distinct rows.
    # Rather than do an expensive and error-prone batch migration
    # to find and remove the duplicates, we'll just remove all records
    # from the table.
    #
    # The `cyclonedx_sbom_ingestion` feature flag should
    # be OFF in all environments to avoid having more duplicate records
    # added between this migration and the one where the new unqiue index
    # is added.

    # TRUNCATE is a DDL statement (it drops the table and re-creates it), so we want to run the
    # migration in DDL mode, but we also don't want to execute it against all schemas because
    # it's considered a write operation. So, we'll manually check and skip the migration if
    # it's on not `:gitlab_main`.
    return unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(:gitlab_main)

    execute('TRUNCATE sbom_occurrences')
  end

  def down
    # no-op
  end
end
