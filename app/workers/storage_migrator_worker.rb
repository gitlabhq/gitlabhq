# frozen_string_literal: true

class StorageMigratorWorker
  include ApplicationWorker

  def perform(start, finish)
    migrator = Gitlab::HashedStorage::Migrator.new
    migrator.bulk_migrate(start, finish)
  end
end
