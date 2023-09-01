# frozen_string_literal: true

module BackgroundMigration
  module SingleDatabaseWorker
    extend ActiveSupport::Concern

    include ApplicationWorker

    MAX_LEASE_ATTEMPTS = 5
    BACKGROUND_MIGRATIONS_DELAY = 4.hours.freeze

    included do
      data_consistency :always

      sidekiq_options retry: 3

      feature_category :database
      urgency :throttled
      loggable_arguments 0, 1
    end

    class_methods do
      # The minimum amount of time between processing two jobs of the same migration
      # class.
      #
      # This interval is set to 2 or 5 minutes so autovacuuming and other
      # maintenance related tasks have plenty of time to clean up after a migration
      # has been performed.
      def minimum_interval
        2.minutes.to_i
      end

      def tracking_database
        raise NotImplementedError, "#{self.name} does not implement #{__method__}"
      end
    end

    # Performs the background migration.
    #
    # See Gitlab::BackgroundMigration.perform for more information.
    #
    # class_name - The class name of the background migration to run.
    # arguments - The arguments to pass to the migration class.
    # lease_attempts - The number of times we will try to obtain an exclusive
    #   lease on the class before giving up. See MR for more discussion.
    #   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45298#note_434304956
    def perform(class_name, arguments = [], lease_attempts = MAX_LEASE_ATTEMPTS)
      should_skip = Feature.enabled?(:disallow_database_ddl_feature_flags, type: :ops) ||
        Feature.disabled?(:execute_background_migrations, type: :ops)

      if should_skip
        # Delay execution of background migrations
        self.class.perform_in(BACKGROUND_MIGRATIONS_DELAY, class_name, arguments, lease_attempts)

        Sidekiq.logger.info(
          class: self.class.name,
          database: self.class.tracking_database,
          message: 'skipping execution, migration rescheduled')

        return
      end

      job_coordinator.with_shared_connection do
        perform_with_connection(class_name, arguments, lease_attempts)
      end
    end

    private

    def tracking_database
      self.class.tracking_database
    end

    def job_coordinator
      @job_coordinator ||= Gitlab::BackgroundMigration.coordinator_for_database(tracking_database)
    end

    def perform_with_connection(class_name, arguments, lease_attempts)
      with_context(caller_id: class_name.to_s) do
        retried = lease_attempts != MAX_LEASE_ATTEMPTS
        attempts_left = lease_attempts - 1
        should_perform, ttl = perform_and_ttl(class_name, attempts_left, retried)

        break if should_perform.nil?

        if should_perform
          job_coordinator.perform(class_name, arguments)
        else
          # If the lease could not be obtained this means either another process is
          # running a migration of this class or we ran one recently. In this case
          # we'll reschedule the job in such a way that it is picked up again around
          # the time the lease expires.
          self.class
            .perform_in(ttl || self.class.minimum_interval, class_name, arguments, attempts_left)
        end
      end
    end

    def perform_and_ttl(class_name, attempts_left, retried)
      # In test environments `perform_in` will run right away. This can then
      # lead to stack level errors in the above `#perform`. To work around this
      # we'll just perform the migration right away in the test environment.
      return [true, nil] if always_perform?

      lease = lease_for(class_name, retried)
      lease_obtained = !!lease.try_obtain
      healthy_db = healthy_database?
      perform = lease_obtained && healthy_db

      database_unhealthy_counter.increment(db_config_name: tracking_database) if lease_obtained && !healthy_db

      # When the DB is unhealthy or the lease can't be obtained after several tries,
      # then give up on the job and log a warning. Otherwise we could end up in
      # an infinite rescheduling loop. Jobs can be tracked in the database with the
      # use of Gitlab::Database::BackgroundMigrationJob
      if !perform && attempts_left < 0
        msg = if !lease_obtained
                'Job could not get an exclusive lease after several tries. Giving up.'
              else
                'Database was unhealthy after several tries. Giving up.'
              end

        Sidekiq.logger.warn(class: class_name, message: msg, job_id: jid)

        return [nil, nil]
      end

      [perform, lease.ttl]
    end

    def lease_for(class_name, retried)
      Gitlab::ExclusiveLease
        .new(lease_key_for(class_name, retried), timeout: self.class.minimum_interval)
    end

    def lease_key_for(class_name, retried)
      key = "#{self.class.name}:#{class_name}"
      # We use a different exclusive lock key for retried jobs to allow them running concurrently with the scheduled jobs.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68763 for more information.
      key += ":retried" if retried
      key
    end

    def always_perform?
      Rails.env.test?
    end

    # Returns true if the database is healthy enough to allow the migration to be
    # performed.
    #
    # class_name - The name of the background migration that we might want to
    #              run.
    def healthy_database?
      !Postgresql::ReplicationSlot.lag_too_great?
    end

    def database_unhealthy_counter
      Gitlab::Metrics.counter(
        :background_migration_database_health_reschedules,
        'The number of times a background migration is rescheduled because the database is unhealthy.'
      )
    end
  end
end
