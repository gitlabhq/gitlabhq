class BackgroundMigrationWorker
  include ApplicationWorker

  # The minimum amount of time between processing two jobs of the same migration
  # class.
  #
  # This interval is set to 5 minutes so autovacuuming and other maintenance
  # related tasks have plenty of time to clean up after a migration has been
  # performed.
  MIN_INTERVAL = 5.minutes.to_i

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
      self.class.perform_in(ttl || MIN_INTERVAL, class_name, arguments)
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

      [lease.try_obtain, lease.ttl]
    end
  end

  def lease_for(class_name)
    Gitlab::ExclusiveLease
      .new("#{self.class.name}:#{class_name}", timeout: MIN_INTERVAL)
  end

  def always_perform?
    Rails.env.test?
  end
end
