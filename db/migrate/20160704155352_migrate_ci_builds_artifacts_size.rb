require 'time'

class MigrateCiBuildsArtifactsSize < ActiveRecord::Migration
  DOWNTIME = false
  BATCH = 1000

  Task = Struct.new(:id, :artifacts_size)

  def up(dry = false)
    cleanup_ci_builds_artifacts_file unless dry

    loop_through_tasks(dry) do |tasks|
      execute(update_build_sql(tasks)) unless dry || tasks.empty?
    end
  end

  def loop_through_tasks(dry)
    n = 0

    loop do
      say("Fetching and updating first #{n + BATCH} ci_builds...")

      build_ids = select_all(build_ids_sql(BATCH, n))

      if build_ids.empty?
        break
      else
        yield(construct_tasks(build_ids, dry))

        n += BATCH
      end
    end
  end

  def construct_tasks(build_ids, dry)
    load_builds(build_ids).inject([]) do |result, build|
      artifacts_size = retrieve_artifacts_size(build, dry)
      result << Task.new(build['id'], artifacts_size) if artifacts_size
      result
    end
  end

  def load_builds(build_ids)
    builds = select_all(load_builds_sql(build_ids)).sort_by do |b|
      b['gl_project_id']
    end

    ci_ids = select_all(load_projects_sql(builds))

    builds.zip(ci_ids).map do |b, c|
      if c
        b.merge(c)
      else
        b
      end
    end
  end

  def retrieve_artifacts_size(build, dry)
    store_dir = File.join(artifacts_prefix, find_artifacts_path(build))
    store_path = File.join(store_dir, build['artifacts_file'])

    if File.exist?(store_path)
      File.size(store_path)
    elsif !dry
      say("File is unexpectedly missing for #{build['id']} at #{store_path}")
      nil
    end
  end

  def find_artifacts_path(build)
    prefix_time = Time.parse(build['created_at']).strftime('%Y_%m')

    if build['ci_id']
      artifacts_path_old_or_new(prefix_time, build)
    else
      artifacts_path_new(prefix_time, build)
    end
  end

  def artifacts_path_old_or_new(prefix_time, build)
    old = artifacts_path_old(prefix_time, build)
    old_store = File.join(artifacts_prefix, old)

    if File.directory?(old_store)
      old
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

  def cleanup_ci_builds_artifacts_file
    execute(normalize_sql(<<-SQL))
      UPDATE ci_builds SET artifacts_file = NULL
        WHERE artifacts_file = ''
    SQL
  end

  def update_build_sql(tasks)
    whens = tasks.map do |t|
      "WHEN id = #{t.id} THEN #{t.artifacts_size}"
    end.join(' ')

    ids = tasks.map(&:id).join(', ')

    normalize_sql(<<-SQL)
      UPDATE ci_builds
        SET artifacts_size = CASE #{whens} ELSE NULL END
        WHERE id IN (#{ids})
    SQL
  end

  def build_ids_sql(limit, offset)
    normalize_sql(<<-SQL)
      SELECT id
        FROM ci_builds
        WHERE artifacts_size IS NULL
          AND artifacts_file IS NOT NULL
          AND artifacts_file <> ''
          AND gl_project_id IS NOT NULL
        ORDER BY id
        LIMIT #{limit}
        OFFSET #{offset}
    SQL
  end

  def load_builds_sql(build_ids)
    ids = build_ids.map { |b| b['id'] }.join(', ')

    normalize_sql(<<-SQL)
      SELECT id, artifacts_file, created_at, gl_project_id
        FROM ci_builds
        WHERE id IN (#{ids})
    SQL
  end

  def load_projects_sql(builds)
    gl_project_ids = builds.map { |b| b['gl_project_id'] }.join(', ')

    normalize_sql(<<-SQL)
      SELECT ci_id
        FROM projects
        WHERE id IN (#{gl_project_ids})
        ORDER BY id ASC
    SQL
  end

  def normalize_sql(sql)
    sql.tr("\n", ' ').squeeze(' ').strip
  end
end
