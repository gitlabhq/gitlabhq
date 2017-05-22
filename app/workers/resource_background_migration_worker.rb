class ResourceBackgroundMigrationWorker
  include Sidekiq::Worker
  # include MigrationsQueue TODO

  def perform(resource, records)
    Array(records).each do |id, record_version|
      ActiveRecord::Base.transaction do
        resource.constantize.tap do |model|
          model.migrations(record_version).each do |version, migration|
            migration.perform(id, version, model)
          end
        end
      end
    end
  end
end
