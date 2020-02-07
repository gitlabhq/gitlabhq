# frozen_string_literal: true

class MigrateEpicNotesMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  INDEX_NAME = 'epic_mentions_temp_index'
  INDEX_CONDITION = "note LIKE '%@%'::text AND notes.noteable_type = 'Epic'"
  QUERY_CONDITIONS = "#{INDEX_CONDITION} AND epic_user_mentions.epic_id IS NULL"
  JOIN = 'INNER JOIN epics ON epics.id = notes.noteable_id LEFT JOIN epic_user_mentions ON notes.id = epic_user_mentions.note_id'

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    return unless Gitlab.ee?

    # create temporary index for notes with mentions, may take well over 1h
    add_concurrent_index(:notes, :id, where: INDEX_CONDITION, name: INDEX_NAME)

    Note
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(notes.id)'), Arel.sql('MAX(notes.id)')).first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Epic', JOIN, QUERY_CONDITIONS, true, *range])
    end
  end

  def down
    # no-op
    # temporary index is to be dropped in a different migration in an upcoming release:
    # https://gitlab.com/gitlab-org/gitlab/issues/196842
  end
end
