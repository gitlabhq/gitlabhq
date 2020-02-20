# frozen_string_literal: true

class MigrateEpicMentionsToDb < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  JOIN = "LEFT JOIN epic_user_mentions on epics.id = epic_user_mentions.epic_id"
  QUERY_CONDITIONS = "(description like '%@%' OR title like '%@%') AND epic_user_mentions.epic_id is null"

  class Epic < ActiveRecord::Base
    include EachBatch

    self.table_name = 'epics'
  end

  def up
    return unless Gitlab.ee?

    Epic
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(epics.id)'), Arel.sql('MAX(epics.id)')).first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Epic', JOIN, QUERY_CONDITIONS, false, *range])
    end
  end

  def down
    # no-op
  end
end
