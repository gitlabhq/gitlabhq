class CleanupBuildStageMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TMP_INDEX = 'tmp_id_stage_partial_null_index'.freeze

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_builds'
    self.inheritance_column = :_type_disabled
  end

  def up
    disable_statement_timeout(transaction: false) do
      ##
      # We steal from the background migrations queue to catch up with the
      # scheduled migrations set.
      #
      Gitlab::BackgroundMigration.steal('MigrateBuildStage')

      ##
      # We add temporary index, to make iteration over batches more performant.
      # Conditional here is to avoid the need of doing that in a separate
      # migration file to make this operation idempotent.
      #
      unless index_exists_by_name?(:ci_builds, TMP_INDEX)
        add_concurrent_index(:ci_builds, :id, where: 'stage_id IS NULL', name: TMP_INDEX)
      end

      ##
      # We check if there are remaining rows that should be migrated (for example
      # if Sidekiq / Redis fails / is restarted, what could result in not all
      # background migrations being executed correctly.
      #
      # We migrate remaining rows synchronously in a blocking way, to make sure
      # that when this migration is done we are confident that all rows are
      # already migrated.
      #
      Build.where('stage_id IS NULL').each_batch(of: 50) do |batch|
        range = batch.pluck('MIN(id)', 'MAX(id)').first

        Gitlab::BackgroundMigration::MigrateBuildStage.new.perform(*range)
      end

      ##
      # We remove temporary index, because it is not required during standard
      # operations and runtime.
      #
      remove_concurrent_index_by_name(:ci_builds, TMP_INDEX)
    end
  end

  def down
    if index_exists_by_name?(:ci_builds, TMP_INDEX)
      disable_statement_timeout(transaction: false) do
        remove_concurrent_index_by_name(:ci_builds, TMP_INDEX)
      end
    end
  end
end
