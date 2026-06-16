# frozen_string_literal: true

class RemoveLeftoverGroupWikiRepositoryDeletions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    loop do
      result = execute <<~SQL
        DELETE FROM "loose_foreign_keys_deleted_records"
        WHERE
          ("loose_foreign_keys_deleted_records"."partition", "loose_foreign_keys_deleted_records"."id") IN (
            SELECT "loose_foreign_keys_deleted_records"."partition", "loose_foreign_keys_deleted_records"."id"
            FROM "loose_foreign_keys_deleted_records"
            WHERE
              "loose_foreign_keys_deleted_records"."fully_qualified_table_name" = 'public.group_wiki_repositories' AND
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
