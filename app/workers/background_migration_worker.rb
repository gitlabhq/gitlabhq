class BackgroundMigrationWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  # Enqueues a number of jobs in bulk.
  #
  # The `jobs` argument should be an Array of Arrays, each sub-array must be in
  # the form:
  #
  #     [migration-class, [arg1, arg2, ...]]
  def self.perform_bulk(jobs)
    Sidekiq::Client.push_bulk('class' => self,
                              'queue' => sidekiq_options['queue'],
                              'args' => jobs)
  end

  # Schedules multiple jobs in bulk, with a delay.
  #
  def self.perform_bulk_in(delay, jobs)
    now = Time.now.to_i
    schedule = now + delay.to_i

    raise ArgumentError if schedule <= now

    Sidekiq::Client.push_bulk('class' => self,
                              'queue' => sidekiq_options['queue'],
                              'args' => jobs,
                              'at' => schedule)
  end

  # Performs the background migration.
  #
  # See Gitlab::BackgroundMigration.perform for more information.
  def perform(class_name, arguments = [])
    Gitlab::BackgroundMigration.perform(class_name, arguments)
  end
end
