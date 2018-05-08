class CleanupBuildStageMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled
  end

  def up
    Gitlab::BackgroundMigration.steal('MigrateBuildStage')

    Build.where('stage_id IS NULL').each_batch(of: 50) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::MigrateBuildStage.new.perform(*range)
    end
  end

  def down
    # noop
  end
end
