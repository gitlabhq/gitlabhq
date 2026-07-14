# frozen_string_literal: true

module Import
  module BulkImports
    class CommitNotesExportService < ::BulkImports::TreeExportService
      # Non-batched export: serializes the whole commit_notes relation into a single
      # NDJSON file. Walks the repository for commit SHAs (CommitNotesBatcher) and
      # serializes the notes.
      def execute
        return unless commit_notes_present?

        batcher.each_batch { |shas| serialize_commit_notes(shas) }
      end

      # Batched export: serializes a single batch of commit-note IDs into its own
      # NDJSON file. The IDs were resolved by BatchedRelationExportService.
      def export_batch(note_ids)
        ensure_export_file_exists

        serializer.serialize_relation(relation_definition, batch_ids: Array.wrap(note_ids))
      end

      private

      def serialize_commit_notes(shas)
        ensure_export_file_exists

        return if shas.blank?

        note_ids = Note.commit_note_ids_for_shas(shas, portable.id)

        serializer.serialize_relation(relation_definition, batch_ids: note_ids)
      end

      # rubocop:disable CodeReuse/ActiveRecord -- specific to this service
      def commit_notes_present?
        portable.notes.where(noteable_type: 'Commit').exists?
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def ensure_export_file_exists
        FileUtils.mkdir_p(export_path)
        FileUtils.touch(File.join(export_path, exported_filename))
      end

      def batcher
        @batcher ||= ::Import::Export::Project::CommitNotesBatcher.new(portable)
      end
    end
  end
end
