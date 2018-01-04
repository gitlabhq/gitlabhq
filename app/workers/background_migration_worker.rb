class BackgroundMigrationWorker
  include ApplicationWorker

  # Performs the background migration.
  #
  # See Gitlab::BackgroundMigration.perform for more information.
  def perform(class_name, arguments = [])
    Gitlab::BackgroundMigration.perform(class_name, arguments)
  end
end
