# frozen_string_literal: true

class BackgroundMigrationWorker
  include ApplicationWorker

  # The minimum amount of time between processing two jobs of the same migration
  # class.
  #
  # This interval is set to 2 or 5 minutes so autovacuuming and other
  # maintenance related tasks have plenty of time to clean up after a migration
  # has been performed.
  def self.minimum_interval
    2.minutes.to_i
  end

  # Performs the background migration.
  #
  # See Gitlab::BackgroundMigration.perform for more information.
  #
  # class_name - The class name of the background migration to run.
  # arguments - The arguments to pass to the migration class.
  def perform(class_name, arguments = [])
    should_perform, ttl = perform_and_ttl(class_name)

    if should_perform
      Gitlab::BackgroundMigration.perform(class_name, arguments)
    else
      # If the lease could not be obtained this means either another process is
      # running a migration of this class or we ran one recently. In this case
      # we'll reschedule the job in such a way that it is picked up again around
      # the time the lease expires.
      self.class
        .perform_in(ttl || self.class.minimum_interval, class_name, arguments)
    end
  end

  def perform_and_ttl(class_name)
    if always_perform?
      # In test environments `perform_in` will run right away. This can then
      # lead to stack level errors in the above `#perform`. To work around this
      # we'll just perform the migration right away in the test environment.
      [true, nil]
    else
      lease = lease_for(class_name)
      perform = !!lease.try_obtain

      # If we managed to acquire the lease but the DB is not healthy, then we
      # want to simply reschedule our job and try again _after_ the lease
      # expires.
      if perform && !healthy_database?
        database_unhealthy_counter.increment

        perform = false
      end

      [perform, lease.ttl]
    end
  end

  def lease_for(class_name)
    Gitlab::ExclusiveLease
      .new(lease_key_for(class_name), timeout: self.class.minimum_interval)
  end

  def lease_key_for(class_name)
    "#{self.class.name}:#{class_name}"
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
