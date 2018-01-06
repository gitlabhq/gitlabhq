class ScheduleBuildStageMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateBuildStage'.freeze
  BATCH = 10_000

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
  end

  def change
    Build.where('stage_id IS NULL').each_batch(of: BATCH) do |builds, index|
      builds.pluck(:id).map { |id| [MIGRATION, [id]] }.tap do |migrations|
        BackgroundMigrationWorker.bulk_perform_in(index.minutes, migrations)
      end
    end
  end
end
