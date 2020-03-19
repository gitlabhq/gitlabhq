# frozen_string_literal: true

class MigrateDesignNotesMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  INDEX_NAME = 'design_mentions_temp_index'
  INDEX_CONDITION = "note LIKE '%@%'::text AND notes.noteable_type = 'DesignManagement::Design'"
  QUERY_CONDITIONS = "#{INDEX_CONDITION} AND design_user_mentions.design_id IS NULL"
  JOIN = 'INNER JOIN design_management_designs ON design_management_designs.id = notes.noteable_id LEFT JOIN design_user_mentions ON notes.id = design_user_mentions.note_id'

  class DesignUserMention < ActiveRecord::Base
    include EachBatch

    self.table_name = 'design_user_mentions'
  end

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    return unless Gitlab.ee?

    # cleanup design user mentions with no actual mentions,
    # re https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24586#note_285982468
    DesignUserMention
      .where(mentioned_users_ids: nil)
      .where(mentioned_groups_ids: nil)
      .where(mentioned_projects_ids: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end

    # create temporary index for notes with mentions, may take well over 1h
    add_concurrent_index(:notes, :id, where: INDEX_CONDITION, name: INDEX_NAME)

    Note
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(notes.id)'), Arel.sql('MAX(notes.id)')).first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['DesignManagement::Design', JOIN, QUERY_CONDITIONS, true, *range])
    end
  end

  def down
    # no-op
    # temporary index is to be dropped in a different migration in an upcoming release:
    # https://gitlab.com/gitlab-org/gitlab/issues/196842
  end
end
