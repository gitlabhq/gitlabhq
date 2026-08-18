# frozen_string_literal: true

module Import
  module BulkImports
    class CommitNotesExportService < ::BulkImports::TreeExportService
      # Non-batched export: serializes the whole commit_notes relation into a single
      # NDJSON file. Uses the default notes-table pagination first and only walks
      # the repository (CommitNotesBatcher) when that pagination times out, since
      # the repo walk is expensive.
      # See https://gitlab.com/gitlab-org/gitlab/-/work_items/554953.
      def execute
        super
      rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- notes-table pagination timed out; fall back to the repository walk
        log_fallback(e)
        export_via_repository
      end

      # Batched export: serializes a single batch of commit-note IDs into its own
      # NDJSON file. The IDs were resolved by BatchedRelationExportService.
      def export_batch(note_ids)
        ensure_export_file_exists

        serializer.serialize_relation(relation_definition, batch_ids: Array.wrap(note_ids))
      end

      private

      def export_via_repository
        # Clear any rows the timed-out pagination already streamed so the
        # repository walk (which appends) does not duplicate them.
        reset_export_file

        return unless commit_notes_present?

        batcher.each_batch { |shas| serialize_commit_notes(shas) }
      end

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

      def reset_export_file
        path = File.join(export_path, exported_filename)
        File.truncate(path, 0) if File.exist?(path)
      end

      def log_fallback(error)
        Gitlab::Export::Logger.warn(
          message: 'commit_notes export via notes-table pagination timed out, falling back to git repository walk',
          relation: relation,
          project_id: portable.id,
          Labkit::Fields::ERROR_MESSAGE => error.message
        )
      end

      def batcher
        @batcher ||= ::Import::Export::Project::CommitNotesBatcher.new(portable)
      end
    end
  end
end
