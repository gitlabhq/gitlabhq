class MigrateCiBuildsArtifactsSize < ActiveRecord::Migration
  DOWNTIME = false

  def up
    cleanup_ci_builds_artifacts_file

    select_all(builds_sql).each do |build|
      ArtifactsSizeWorker.perform_async(build['id'])
    end
  end

  def cleanup_ci_builds_artifacts_file
   execute(normalize_sql(<<-SQL))
     UPDATE ci_builds SET artifacts_file = NULL
       WHERE artifacts_file = ''
   SQL
  end

  def builds_sql
    normalize_sql(<<-SQL)
      SELECT id FROM ci_builds
        WHERE artifacts_size IS NULL
          AND artifacts_file IS NOT NULL
          AND artifacts_file <> ''
    SQL
  end

  def normalize_sql(sql)
    sql.tr("\n", ' ').squeeze(' ').strip
  end
end
