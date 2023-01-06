# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Renames all system notes created when an issuable task is checked/unchecked
    # from `task` into `checklist item`
    # `marked the task **Task 1** as incomplete` => `marked the checklist item **Task 1** as incomplete`
    class RenameTaskSystemNoteToChecklistItem < BatchedMigrationJob
      REPLACE_REGEX = '\Amarked\sthe\stask'
      TEXT_REPLACEMENT = 'marked the checklist item'

      scope_to ->(relation) {
        relation.where(system_note_metadata: { action: :task })
      }

      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.connection.execute <<~SQL
            UPDATE notes
            SET note = REGEXP_REPLACE(notes.note,'#{REPLACE_REGEX}', '#{TEXT_REPLACEMENT}')
            FROM (#{sub_batch.select(:note_id).to_sql}) AS metadata_fields(note_id)
            WHERE notes.id = note_id
          SQL
        end
      end
    end
  end
end
