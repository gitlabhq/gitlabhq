class RepositoryCheckWorker
  include Sidekiq::Worker

  RUN_TIME = 3600

  sidekiq_options retry: false

  def perform
    start = Time.now

    # This loop will break after a little more than one hour ('a little
    # more' because `git fsck` may take a few minutes), or if it runs out of
    # projects to check. By default sidekiq-cron will start a new
    # RepositoryCheckWorker each hour so that as long as there are repositories to
    # check, only one (or two) will be checked at a time.
    project_ids.each do |project_id|
      break if Time.now - start >= RUN_TIME

      next if !try_obtain_lease(project_id)

      SingleRepositoryCheckWorker.new.perform(project_id)
    end
  end

  private

  # In an ideal world we would use Project.where(...).find_each.
  # Unfortunately, calling 'find_each' drops the 'where', so we must build
  # an array of IDs instead.
  def project_ids
    limit = 10_000
    never_checked_projects = Project.where('last_repository_check_at IS NULL').limit(limit).
      pluck(:id)
    old_check_projects = Project.where('last_repository_check_at < ?', 1.week.ago).
      reorder('last_repository_check_at ASC').limit(limit).pluck(:id)
    never_checked_projects + old_check_projects
  end

  def try_obtain_lease(id)
    # Use a 24-hour timeout because on servers/projects where 'git fsck' is
    # super slow we definitely do not want to run it twice in parallel.
    lease = Gitlab::ExclusiveLease.new(
      "project_repository_check:#{id}",
      timeout: 24.hours
    )
    lease.try_obtain
  end
end
