# rubocop:disable all
class UpdateCiCommit < ActiveRecord::Migration
  # This migration can be run online, but needs to be executed for the second time after restarting Unicorn workers
  # Otherwise Offline migration should be used.
  def change
    execute("UPDATE ci_commits SET status=#{status}, ref=#{ref}, tag=#{tag} WHERE status IS NULL")
  end

  private

  def status
    builds = '(SELECT COUNT(*) FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id)'
    success = "(SELECT COUNT(*) FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id AND status='success')"
    ignored = "(SELECT COUNT(*) FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id AND (status='failed' OR status='canceled') AND allow_failure)"
    pending = "(SELECT COUNT(*) FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id AND status='pending')"
    running = "(SELECT COUNT(*) FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id AND status='running')"
    canceled = "(SELECT COUNT(*) FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id AND status='canceled')"

    "(CASE
      WHEN #{builds}=0 THEN 'skipped'
      WHEN #{builds}=#{success}+#{ignored} THEN 'success'
      WHEN #{builds}=#{pending} THEN 'pending'
      WHEN #{builds}=#{canceled} THEN 'canceled'
      WHEN #{running}+#{pending}>0 THEN 'running'
      ELSE 'failed'
    END)"
  end

  def ref
    '(SELECT ref FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id ORDER BY id DESC LIMIT 1)'
  end

  def tag
    '(SELECT tag FROM ci_builds WHERE ci_builds.commit_id=ci_commits.id ORDER BY id DESC LIMIT 1)'
  end
end
