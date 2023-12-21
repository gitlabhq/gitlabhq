# frozen_string_literal: true

class CleanupGroupLevelWorkItems < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 100

  class MigrationIssue < MigrationRecord
    self.table_name = :issues

    include EachBatch
  end

  class MigrationNote < MigrationRecord
    self.table_name = :notes

    include EachBatch
  end

  class MigrationLabelLink < MigrationRecord
    self.table_name = :label_links

    include EachBatch
  end

  class MigrationTodo < MigrationRecord
    self.table_name = :todos

    include EachBatch
  end

  def up
    MigrationIssue.where(project_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      logger.info("deleting #{batch.size} issues at group level: #{batch.pluck(:id)}")

      # cleaning up notes for the batch of issues
      MigrationNote.where(noteable_type: 'Issue', noteable_id: batch).each_batch(of: BATCH_SIZE) do |note_batch|
        logger.info("deleting #{note_batch.size} notes for issues at group level: #{note_batch.pluck(:id)}")
        note_batch.delete_all
      end

      # cleaning up label links for the batch of issues
      MigrationLabelLink.where(target_type: 'Issue', target_id: batch).each_batch(of: BATCH_SIZE) do |label_link_batch|
        logger.info(
          "deleting #{label_link_batch.size} label links for issues at group level: #{label_link_batch.pluck(:id)}"
        )
        label_link_batch.delete_all
      end

      # cleaning up todos for the batch of issues
      MigrationTodo.where(target_type: 'Issue', target_id: batch).each_batch(of: BATCH_SIZE) do |todo_batch|
        logger.info("deleting #{todo_batch.size} todos for issues at group level: #{todo_batch.pluck(:id)}")
        todo_batch.delete_all
      end

      batch.delete_all
    end
  end

  def down
    # no-op
  end

  private

  def logger
    @logger ||= Gitlab::BackgroundMigration::Logger.build
  end
end
