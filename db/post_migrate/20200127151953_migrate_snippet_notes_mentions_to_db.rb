# frozen_string_literal: true

class MigrateSnippetNotesMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10_000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  INDEX_CONDITION = "note LIKE '%@%'::text AND notes.noteable_type = 'Snippet'"
  QUERY_CONDITIONS = "#{INDEX_CONDITION} AND snippet_user_mentions.snippet_id IS NULL"
  JOIN = 'INNER JOIN snippets ON snippets.id = notes.noteable_id LEFT JOIN snippet_user_mentions ON notes.id = snippet_user_mentions.note_id'

  disable_ddl_transaction!

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
      migrate_in(index * DELAY, MIGRATION, ['Snippet', JOIN, QUERY_CONDITIONS, true, *range])
    end
  end

  def down
    # no-op
    # temporary index is to be dropped in a different migration in an upcoming release:
    # https://gitlab.com/gitlab-org/gitlab/issues/196842
  end
end
