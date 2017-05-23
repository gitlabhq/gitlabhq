require 'work_queue'

class MigrateOldTraces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    builds_with_traces(min_id || 0).each do |build|
      work_queue.enqueue_b do
        migrate_trace(build)
      end
    end

  ensure
    work_queue.join
  end

  def down
  end

  private

  def migrate_trace(build)
    source = source_trace(build)
    target = target_trace(build)
    return unless File.exists?(source)

    ensure_path(target)
    FileUtils.move(source, target)
  end

  def ensure_path(path)
    directory = File.dirname(path)
    unless Dir.exist?(default_directory)
      FileUtils.mkdir_p(directory)
    end
  end

  def source_trace(build)
    File.join(Gitlab.config.gitlab_ci.builds_path,
      build['created_at'].utc.strftime('%Y_%m'),
      build['ci_id'].to_s, 
      build['id'].to_s + ".log")
  end

  def target_trace(build)
    File.join(Gitlab.config.gitlab_ci.builds_path,
      build['created_at'].utc.strftime('%Y_%m'),
      build['project_id'].to_s, 
      build['id'].to_s + ".log")
  end

  def min_id
    select_value <<-SQL.strip_heredoc
      SELECT min(ci_builds.id) as min_id FROM ci_builds
        JOIN projects ON ci_builds.project_id = projects.id 
         AND projects.ci_id IS NULL
    SQL
  end

  def builds_with_traces(before_id)
    select_all <<-SQL.strip_heredoc
      SELECT ci_builds.id, ci_builds.project_id,
             projects.ci_id, ci_builds.created_at
        FROM ci_builds
        JOIN projects ON ci_builds.project_id = projects.id 
       WHERE ci_builds.id < #{before_id}
         AND ci_builds.erased_at IS NULL
         AND projects.ci_id IS NOT NULL
    SQL
  end

  def work_queue
    @work_queue ||= WorkQueue.new(10)
  end
end
