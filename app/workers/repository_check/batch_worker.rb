# frozen_string_literal: true

module RepositoryCheck
  class BatchWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include RepositoryCheckQueue
    include ExclusiveLeaseGuard

    RUN_TIME = 3600
    BATCH_SIZE = 10_000
    LEASE_TIMEOUT = 1.hour

    attr_reader :shard_name

    loggable_arguments 0

    def perform(shard_name)
      @shard_name = shard_name

      return unless Gitlab::CurrentSettings.repository_checks_enabled
      return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

      try_obtain_lease do
        perform_repository_checks
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def lease_key
      "repository_check_batch_worker:#{shard_name}"
    end

    def perform_repository_checks
      start = Time.current

      # This loop will break after a little more than one hour ('a little
      # more' because `git fsck` may take a few minutes), or if it runs out of
      # projects to check. By default sidekiq-cron will start a new
      # RepositoryCheckWorker each hour so that as long as there are repositories to
      # check, only one (or two) will be checked at a time.
      project_ids.each do |project_id|
        break if Time.current - start >= RUN_TIME

        next unless try_obtain_lease_for_project(project_id)

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
      never_checked_project_ids(BATCH_SIZE) + old_checked_project_ids(BATCH_SIZE)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def never_checked_project_ids(batch_size)
      projects_on_shard.where(last_repository_check_at: nil)
        .where('created_at < ?', 24.hours.ago)
        .limit(batch_size).pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def old_checked_project_ids(batch_size)
      projects_on_shard.where.not(last_repository_check_at: nil)
        .where('last_repository_check_at < ?', 1.month.ago)
        .reorder(last_repository_check_at: :asc)
        .limit(batch_size).pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def projects_on_shard
      Project.where(repository_storage: shard_name)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def try_obtain_lease_for_project(id)
      # Use a 24-hour timeout because on servers/projects where 'git fsck' is
      # super slow we definitely do not want to run it twice in parallel.
      Gitlab::ExclusiveLease.new(
        "project_repository_check:#{id}",
        timeout: 24.hours
      ).try_obtain
    end
  end
end

RepositoryCheck::BatchWorker.prepend_mod_with('RepositoryCheck::BatchWorker')
