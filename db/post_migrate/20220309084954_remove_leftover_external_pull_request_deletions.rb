# frozen_string_literal: true

class RemoveLeftoverExternalPullRequestDeletions < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    # Delete all pending record deletions in the public.external_pull_requests until
    # there are no more rows left.
    loop do
      result = execute <<~SQL
      DELETE FROM "loose_foreign_keys_deleted_records"
      WHERE
      ("loose_foreign_keys_deleted_records"."partition", "loose_foreign_keys_deleted_records"."id") IN (
        SELECT "loose_foreign_keys_deleted_records"."partition", "loose_foreign_keys_deleted_records"."id"
        FROM "loose_foreign_keys_deleted_records"
        WHERE
        "loose_foreign_keys_deleted_records"."fully_qualified_table_name" = 'public.external_pull_requests' AND
        "loose_foreign_keys_deleted_records"."status" = 1
        LIMIT 100
      )
      SQL

      break if result.cmd_tuples == 0
    end
  end

  def down
    # no-op
  end
end
