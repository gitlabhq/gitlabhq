# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackupAndRemoveNotesWithNullNoteableType < BatchedMigrationJob
      operation_name :delete_all
      scope_to ->(relation) { relation.where(noteable_type: nil) }
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          Note.transaction do
            Note.connection.execute <<~SQL
              INSERT INTO temp_notes_backup #{sub_batch.to_sql}
            SQL

            sub_batch.delete_all
          end
        end
      end
    end
  end
end
