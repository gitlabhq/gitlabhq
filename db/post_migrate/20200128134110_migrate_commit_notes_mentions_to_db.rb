# frozen_string_literal: true

class MigrateCommitNotesMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  DELAY = 3.minutes.to_i
  BATCH_SIZE = 1_000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  QUERY_CONDITIONS = "note LIKE '%@%'::text AND notes.noteable_type = 'Commit' AND commit_user_mentions.commit_id IS NULL"
  JOIN = 'LEFT JOIN commit_user_mentions ON notes.id = commit_user_mentions.note_id'

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    Note
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(notes.id)'), Arel.sql('MAX(notes.id)')).first
      migrate_in(index * DELAY, MIGRATION, ['Commit', JOIN, QUERY_CONDITIONS, true, *range])
    end
  end

  def down
    # no-op
    # temporary index is to be dropped in a different migration in an upcoming release:
    # https://gitlab.com/gitlab-org/gitlab/issues/196842
  end
end
