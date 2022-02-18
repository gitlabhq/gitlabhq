# frozen_string_literal: true

class BackgroundMigrationWorker # rubocop:disable Scalability/IdempotentWorker
  include BackgroundMigration::SingleDatabaseWorker

  def self.tracking_database
    @tracking_database ||= Gitlab::BackgroundMigration::DEFAULT_TRACKING_DATABASE
  end
end
