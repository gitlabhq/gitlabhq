# frozen_string_literal: true

class BackfillCadenceIdForBoardsScopedToIteration < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  BATCH_SIZE = 1000
  DELAY = 2.minutes.to_i
  MIGRATION = 'BackfillIterationCadenceIdForBoards'

  class MigrationBoard < ApplicationRecord
    include EachBatch

    self.table_name = 'boards'
  end

  def up
    schedule_backfill_group_boards
    schedule_backfill_project_boards
  end

  def down
    MigrationBoard.where.not(iteration_cadence_id: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pick(Arel.sql('MIN(id)'), Arel.sql('MAX(id)'))
      delay = index * DELAY

      migrate_in(delay, MIGRATION, ['none', 'down', *range])
    end
  end

  private

  def schedule_backfill_project_boards
    MigrationBoard.where(iteration_id: -4).where.not(project_id: nil).where(iteration_cadence_id: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pick(Arel.sql('MIN(id)'), Arel.sql('MAX(id)'))
      delay = index * DELAY

      migrate_in(delay, MIGRATION, ['project', 'up', *range])
    end
  end

  def schedule_backfill_group_boards
    MigrationBoard.where(iteration_id: -4).where.not(group_id: nil).where(iteration_cadence_id: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pick(Arel.sql('MIN(id)'), Arel.sql('MAX(id)'))
      delay = index * DELAY

      migrate_in(delay, MIGRATION, ['group', 'up', *range])
    end
  end
end
