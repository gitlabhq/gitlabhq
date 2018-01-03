module RepositoryCheck
  class BatchWorker
    include ApplicationWorker
    include CronjobQueue

    RUN_TIME = 3600

    def perform
      start = Time.now

      # This loop will break after a little more than one hour ('a little
      # more' because `git fsck` may take a few minutes), or if it runs out of
      # projects to check. By default sidekiq-cron will start a new
      # RepositoryCheckWorker each hour so that as long as there are repositories to
      # check, only one (or two) will be checked at a time.
      project_ids.each do |project_id|
        break if Time.now - start >= RUN_TIME
        break unless current_settings.repository_checks_enabled

        next unless try_obtain_lease(project_id)

        SingleRepositoryWorker.new.perform(project_id)
      end
    end

    private

    # Project.find_each does not support WHERE clauses and
    # Project.find_in_batches does not support ordering. So we just build an
    # array of ID's. This is OK because we do it only once an hour, because
    # getting ID's from Postgres is not terribly slow, and because no user
    # has to sit and wait for this query to finish.
    def project_ids
      limit = 10_000
      never_checked_projects = Project.where('last_repository_check_at IS NULL AND created_at < ?', 24.hours.ago)
        .limit(limit).pluck(:id)
      old_check_projects = Project.where('last_repository_check_at < ?', 1.month.ago)
        .reorder('last_repository_check_at ASC').limit(limit).pluck(:id)
      never_checked_projects + old_check_projects
    end

    def try_obtain_lease(id)
      # Use a 24-hour timeout because on servers/projects where 'git fsck' is
      # super slow we definitely do not want to run it twice in parallel.
      Gitlab::ExclusiveLease.new(
        "project_repository_check:#{id}",
        timeout: 24.hours
      ).try_obtain
    end

    def current_settings
      # No caching of the settings! If we cache them and an admin disables
      # this feature, an active RepositoryCheckWorker would keep going for up
      # to 1 hour after the feature was disabled.
      if Rails.env.test?
        Gitlab::CurrentSettings.fake_application_settings
      else
        ApplicationSetting.current
      end
    end
  end
end
