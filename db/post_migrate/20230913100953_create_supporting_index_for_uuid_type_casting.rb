# frozen_string_literal: true

class CreateSupportingIndexForUuidTypeCasting < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :vulnerability_occurrences
  INDEX_NAME = "tmp_index_vulnerability_occurrences_uuid_cast"

  def up
    index_sql = <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
      ON #{TABLE_NAME}((uuid::uuid))
    SQL

    # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/425037
    prepare_async_index_from_sql(index_sql)
  end

  def down
    unprepare_async_index_by_name(
      TABLE_NAME,
      INDEX_NAME
    )
  end
end
