require 'time'

class MigrateCiBuildsArtifactsSize < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  BATCH = 1000
  THREADS = 8

  Task = Struct.new(:dry, :limit, :offset, :index)

  def up(dry = false)
    cleanup_ci_builds_artifacts_file unless dry

    total = select_all(
      builds_sql_without_limit(select: 'COUNT(b.id)')).first['count'].to_i

    per_thread = total / THREADS
    left = total % THREADS

    works = THREADS.times.map do |index|
      dispatch(index, per_thread, left)
    end

    say(
      "Total #{total} rows, using #{THREADS} threads, splitting as #{works}")
    say("Dry run = #{dry}")

    works.map.with_index do |(limit, offset), index|
      Thread.new(Task.new(dry, limit, offset, index), &method(:worker_work))
    end.each(&:join)
  end

  def dispatch(index, per_thread, left)
    one_more_work = index < left
    limit = per_thread + if one_more_work
                           1
                         else
                           0
                         end
    offset = index * limit + if one_more_work
                               0 # limit = per_thread + 1
                             else
                               left # limit = per_thread
                             end
    [limit, offset]
  end

  def worker_work(task)
    loop_through_builds(task) do |id, store_path, artifacts_size|
      if artifacts_size
        execute(update_build_sql(id, artifacts_size)) unless task.dry
      else
        say("File is unexpectedly missing for #{id} at #{store_path}")
      end
    end
  end

  def loop_through_builds(task, &block)
    n = 0

    if task.limit.zero?
      say("##{task.index} Nothing to do, leaving")
      return
    end

    start_id = select_all(builds_sql(1, task.offset)).first['id']
    stop_id = select_all(builds_sql(1, task.offset + task.limit)).first['id']

    say("##{task.index} Working from #{start_id} <= id < #{stop_id}...")

    loop do
      say("##{task.index} Fetching and updating #{n + BATCH} ci_builds...")

      where = worker_where_sql(start_id, stop_id)
      result = select_all(builds_sql(BATCH, n, where: where))

      if result.empty?
        break
      else
        fill_artifacts_size(result, &block)
        n += BATCH
      end
    end
  end

  def fill_artifacts_size(result)
    result.each do |build|
      store_dir = File.join(artifacts_prefix, find_artifacts_path(build))
      store_path = File.join(store_dir, build['artifacts_file'])
      id = build['id']

      artifacts_size = File.size(store_path) if File.exist?(store_path)

      yield(id, store_path, artifacts_size) if block_given?
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

  def update_build_sql(id, artifacts_size)
    normalize_sql(<<-SQL)
      UPDATE ci_builds SET artifacts_size = #{artifacts_size}
        WHERE id = #{id}
    SQL
  end

  def builds_sql(limit, offset, **args)
    sql = builds_sql_without_limit(**args)

    "#{sql} ORDER BY b.id LIMIT #{limit} OFFSET #{offset}"
  end

  def builds_sql_without_limit(
    select: 'b.id, b.artifacts_file, b.created_at, b.gl_project_id, p.ci_id',
    where: '')
    normalize_sql(<<-SQL)
      SELECT #{select}
        FROM ci_builds b
        INNER JOIN projects p ON p.id = b.gl_project_id
        WHERE b.artifacts_size IS NULL
          AND b.artifacts_file IS NOT NULL
          AND b.artifacts_file <> ''
          #{where}
    SQL
  end

  def worker_where_sql(start_id, stop_id)
    "AND #{start_id} <= b.id AND b.id < #{stop_id}"
  end

  def normalize_sql(sql)
    sql.tr("\n", ' ').squeeze(' ').strip
  end

  def say(*)
    (@mutex ||= Mutex.new).synchronize do
      super
    end
  end
end
