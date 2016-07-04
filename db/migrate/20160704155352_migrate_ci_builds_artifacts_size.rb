require 'time'

class MigrateCiBuildsArtifactsSize < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  BATCH = 1000

  def up
    n = 0

    loop do
      say("Fetching and updating first #{n + BATCH} ci_builds...")

      result = select_all(builds_sql(BATCH, n))

      if result.empty?
        break
      else
        fill_artifacts_size(result)
        n += BATCH
      end
    end
  end

  def fill_artifacts_size(result)
    result.each do |build|
      store_dir = File.join(artifacts_prefix, find_artifacts_path(build))
      store_path = File.join(store_dir, build['artifacts_file'])
      id = build['id']

      if File.exist?(store_path)
        artifacts_size = File.size(store_path)
        execute(update_build_sql(id, artifacts_size))
      else
        say("File is unexpectedly missing for #{id} at #{store_path}")
      end
    end
  end

  def find_artifacts_path(build)
    prefix_time = Time.parse(build['created_at']).strftime('%Y_%m')

    if build['ci_id']
      old = artifacts_path_old(prefix_time, build)
      old_store = File.join(artifacts_prefix, old)

      if File.directory?(old_store)
        old
      else
        artifacts_path_new(prefix_time, build)
      end
    else
      artifacts_path_new(prefix_time, build)
    end
  end

  def artifacts_path_old(prefix_time, build)
    File.join(prefix_time, build['ci_id'], build['id'])
  end

  def artifacts_path_new(prefix_time, build)
    File.join(prefix_time, build['gl_project_id'], build['id'])
  end

  def artifacts_prefix
    Gitlab.config.artifacts.path
  end

  def update_build_sql(id, artifacts_size)
    normalize_sql(<<-SQL)
      UPDATE ci_builds SET artifacts_size = #{artifacts_size}
        WHERE id = #{id}
    SQL
  end

  def builds_sql(limit, offset)
    normalize_sql(<<-SQL)
      SELECT b.id, b.artifacts_file, b.created_at, b.gl_project_id, p.ci_id
        FROM ci_builds b
        INNER JOIN projects p ON p.id = b.gl_project_id
        WHERE b.artifacts_size IS NULL
          AND b.artifacts_file IS NOT NULL
          AND b.artifacts_file <> ''
        ORDER BY b.id
        LIMIT #{limit}
        OFFSET #{offset}
    SQL
  end

  def normalize_sql(sql)
    sql.tr("\n", ' ').squeeze(' ').strip
  end
end
