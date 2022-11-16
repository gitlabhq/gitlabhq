# frozen_string_literal: true

class CreateNextCiPartitionsRecord < Gitlab::Database::Migration[2.0]
  NEXT_PARTITION_ID = 101

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    return unless Gitlab.com?

    execute(<<~SQL)
      INSERT INTO "ci_partitions" ("id", "created_at", "updated_at")
        VALUES (#{NEXT_PARTITION_ID}, now(), now())
        ON CONFLICT DO NOTHING;
    SQL

    reset_pk_sequence!('ci_partitions')
  end

  def down
    return unless Gitlab.com?

    execute(<<~SQL)
      DELETE FROM "ci_partitions"
        WHERE "ci_partitions"."id" = #{NEXT_PARTITION_ID};
    SQL
  end
end
