# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillNoteMetadataNamespaceId < BatchedMigrationJob
      operation_name :set_namespace_id_on_note_metadata_records
      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          # NOTE: Triggers set_sharding_key_for_note_metadata_on_insert_and_update() for all rows
          # where the sharding key is NULL.
          sub_batch.where(namespace_id: nil).touch_all
        end
      end
    end
  end
end
