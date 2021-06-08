# frozen_string_literal: true

class CleanUpPendingBuildsTable < ActiveRecord::Migration[6.0]
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    each_batch('ci_pending_builds', of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM ci_pending_builds
          USING ci_builds
          WHERE ci_builds.id = ci_pending_builds.build_id
            AND ci_builds.status != 'pending'
            AND ci_builds.type = 'Ci::Build'
            AND ci_pending_builds.id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # noop
  end

  private

  def each_batch(table_name, scope: ->(table) { table.all }, of: 1000)
    table = Class.new(ActiveRecord::Base) do
      include EachBatch

      self.table_name = table_name
      self.inheritance_column = :_type_disabled
    end

    scope.call(table).each_batch(of: of) do |batch|
      yield batch.pluck('MIN(id), MAX(id)').first
    end
  end
end
