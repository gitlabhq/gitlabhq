class BackgroundMigrationWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  # Schedules a number of jobs in bulk
  #
  # The `jobs` argument should be an Array of Arrays, each sub-array must be in
  # the form:
  #
  #     [migration-class, [arg1, arg2, ...]]
  def self.perform_bulk(*jobs)
    Sidekiq::Client.push_bulk('class' => self,
                              'queue' => sidekiq_options['queue'],
                              'args' => jobs)
  end

  # Performs the background migration.
  #
  # See Gitlab::BackgroundMigration.perform for more information.
  def perform(class_name, arguments = [])
    Gitlab::BackgroundMigration.perform(class_name, arguments)
  end
end
