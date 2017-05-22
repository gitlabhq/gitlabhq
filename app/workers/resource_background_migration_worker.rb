class ResourceBackgroundMigrationWorker
  include Sidekiq::Worker
  # include MigrationsQueue TODO

  def perform(resource_class, records)
    Array(records).each do |id, version|
      ActiveRecord::Base.transaction do
        resource_class.migrations(version).each do |migration|
          migration.perform(id)
        end
      end
    end
  end
end
