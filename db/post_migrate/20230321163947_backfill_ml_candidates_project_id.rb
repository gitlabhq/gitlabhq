# frozen_string_literal: true

class BackfillMlCandidatesProjectId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<-SQL
      UPDATE ml_candidates
      SET project_id = temp.project_id
      FROM (
          SELECT ml_candidates.id AS id, ml_experiments.project_id AS project_id
          FROM ml_candidates INNER JOIN ml_experiments ON ml_candidates.experiment_id = ml_experiments.id
      ) AS temp
      WHERE ml_candidates.id = temp.id
    SQL

    execute(sql)
  end

  def down; end
end
