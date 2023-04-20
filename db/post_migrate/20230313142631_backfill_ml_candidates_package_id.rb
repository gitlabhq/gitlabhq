# frozen_string_literal: true

class BackfillMlCandidatesPackageId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<-SQL
      UPDATE ml_candidates
      SET package_id = candidate_id_to_package_id.package_id
      FROM (SELECT id as package_id, TRIM(LEADING 'ml_candidates_' FROM name) as candidate_id
            FROM packages_packages
            WHERE name LIKE 'ml_candidate_%'
              and version = '-') AS candidate_id_to_package_id
      WHERE cast(ml_candidates.id as text) = candidate_id_to_package_id.candidate_id
    SQL

    execute(sql)
  end

  def down; end
end
