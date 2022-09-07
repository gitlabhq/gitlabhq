# frozen_string_literal: true

class CreateDefaultPartitionRecord < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    execute(<<~SQL)
      INSERT INTO "ci_partitions" ("id", "created_at", "updated_at")
      VALUES (100, now(), now());
    SQL

    reset_pk_sequence!('ci_partitions')
  end

  def down
    execute(<<~SQL)
      DELETE FROM "ci_partitions" WHERE "ci_partitions"."id" = 100;
    SQL
  end
end
