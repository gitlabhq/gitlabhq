# frozen_string_literal: true

class MigrateSnippetMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10_000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  JOIN = "LEFT JOIN snippet_user_mentions on snippets.id = snippet_user_mentions.snippet_id"
  QUERY_CONDITIONS = "(description like '%@%' OR title like '%@%') AND snippet_user_mentions.snippet_id IS NULL"

  disable_ddl_transaction!

  class Snippet < ActiveRecord::Base
    include EachBatch

    self.table_name = 'snippets'
  end

  def up
    Snippet
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(snippets.id)'), Arel.sql('MAX(snippets.id)')).first
      migrate_in(index * DELAY, MIGRATION, ['Snippet', JOIN, QUERY_CONDITIONS, false, *range])
    end
  end

  def down
    # no-op
  end
end
