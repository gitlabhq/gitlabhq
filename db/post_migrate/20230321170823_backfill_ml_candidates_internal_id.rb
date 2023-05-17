# frozen_string_literal: true

class BackfillMlCandidatesInternalId < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<-SQL
      UPDATE ml_candidates
      SET internal_id = temp.internal_id_num
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY internal_id, id ASC) AS internal_id_num
        FROM ml_candidates
      ) AS temp
      WHERE ml_candidates.id = temp.id
    SQL

    execute(sql)
  end

  def down; end
end
