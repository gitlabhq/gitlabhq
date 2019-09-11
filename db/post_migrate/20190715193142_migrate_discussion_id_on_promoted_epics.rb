# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateDiscussionIdOnPromotedEpics < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # We have ~5000 unique discussion_ids -> this migration will take about 102 minutes
  # (5000/100 * 2 minutes + 2 minutes initial delay) on gitlab.com.
  DOWNTIME = false
  BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes
  MIGRATION = 'FixPromotedEpicsDiscussionIds'

  disable_ddl_transaction!

  class SystemNoteMetadata < ActiveRecord::Base
    self.table_name = 'system_note_metadata'
    self.inheritance_column = :_type_disabled
  end

  class Note < ActiveRecord::Base
    include EachBatch

    has_one :system_note_metadata, class_name: 'MigrateDiscussionIdOnPromotedEpics::SystemNoteMetadata'

    self.table_name = 'notes'
    self.inheritance_column = :_type_disabled

    def self.fetch_discussion_ids_query
      promoted_epics_query = Note
        .joins(:system_note_metadata)
        .where(system: true)
        .where(noteable_type: 'Epic')
        .where(system_note_metadata: { action: 'moved' })
        .select("DISTINCT noteable_id")

      Note.where(noteable_type: 'Epic')
        .where(noteable_id: promoted_epics_query)
        .distinct.pluck(:discussion_id)
    end
  end

  def up
    add_concurrent_index(:system_note_metadata, :note_id, where: "action='moved'", name: 'temp_index_system_note_metadata_on_moved_note_id')
    add_concurrent_index(:notes, [:id, :noteable_id], where: "noteable_type='Epic' AND system", name: 'temp_index_notes_on_id_and_noteable_id' )

    all_discussion_ids = Note.fetch_discussion_ids_query
    all_discussion_ids.in_groups_of(BATCH_SIZE, false).each_with_index do |ids, index|
      delay = DELAY_INTERVAL * (index + 1)
      BackgroundMigrationWorker.perform_in(delay, MIGRATION, [ids])
    end

    remove_concurrent_index(:system_note_metadata, :note_id, where: "action='moved'", name: 'temp_index_system_note_metadata_on_moved_note_id')
    remove_concurrent_index(:notes, [:id, :noteable_id], where: "noteable_type='Epic' AND system", name: 'temp_index_notes_on_id_and_noteable_id')
  end

  def down
    # no-op
  end
end
