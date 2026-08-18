# frozen_string_literal: true

module Ci
  module JobArtifacts
    # File-aware loose FK cleaner for `p_ci_job_artifacts`. Records file paths in
    # `ci_deleted_objects` before deleting rows so `Ci::DeleteObjectsWorker` can
    # remove the underlying files, instead of orphaning them on storage.
    class LooseForeignKeyCleanerService < ::LooseForeignKeys::CleanerService
      BATCH_SIZE = 500

      def execute
        affected_rows = delete_batch_with_file_cleanup

        { affected_rows: affected_rows, table: loose_foreign_key_definition.from_table }
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord -- table-specific cleanup needs the model
      # Uses model-level queries rather than @connection; both route to the same CI db connection.
      def delete_batch_with_file_cleanup
        ::Ci::JobArtifact.transaction do
          artifacts = artifacts_to_clean
          next 0 if artifacts.empty?

          ::Ci::DeletedObject.bulk_import(artifacts)
          ::Ci::JobArtifact
            .where(id: artifacts.map(&:id), partition_id: artifacts.map(&:partition_id).uniq)
            .delete_all
        end
      end

      def artifacts_to_clean
        scope = ::Ci::JobArtifact
          .where(loose_foreign_key_definition.column => parent_record_ids)
          .limit(batch_size)

        scope = scope.lock('FOR UPDATE SKIP LOCKED') if with_skip_locked

        scope.to_a
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def parent_record_ids
        deleted_parent_records.map(&:primary_key_value)
      end

      def batch_size
        loose_foreign_key_definition.options[:delete_limit] || BATCH_SIZE
      end
    end
  end
end
