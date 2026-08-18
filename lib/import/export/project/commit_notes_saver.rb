# frozen_string_literal: true

module Import
  module Export
    module Project
      # Exports `commit_notes` with the default notes-table pagination first
      # (`project.commit_notes.in_batches`, i.e. `WHERE noteable_type='Commit'
      # ORDER BY id LIMIT N`). The query may time out on large projects because
      # there is no supporting index, so on `ActiveRecord::QueryCanceled` we
      # fall back to walking the repo for SHAs and resolving notes via
      # `commit_id IN (...)` (which uses `index_notes_on_commit_id`). The repo
      # walk is expensive, so it is only used for projects that actually time
      # out.
      class CommitNotesSaver < ::Gitlab::ImportExport::Project::RelationSaver
        include ::Gitlab::ImportExport::DurationMeasuring

        def initialize(project:, shared:, user:, params: {})
          super(
            project: project,
            shared: shared,
            relation: Projects::ImportExport::RelationExport::COMMIT_NOTES_RELATION,
            user: user,
            params: params
          )
          @exported_count = 0
        end

        def save
          with_duration_measuring do
            export_commit_notes

            true
          end
        rescue StandardError => e
          shared.error(e)
          false
        end

        private

        def export_commit_notes
          serializer.serialize_relation(relation_schema)
        rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- notes-table pagination timed out; fall back to the repository walk
          log_fallback(e)
          export_via_repository
        end

        def export_via_repository
          # Clear any rows the timed-out pagination already streamed so the
          # repository walk (which appends) does not duplicate them.
          reset_export_file

          return unless commit_notes_present?

          CommitNotesBatcher.new(project).each_batch { |shas| serialize(shas) }

          log_summary
        end

        def serialize(shas)
          note_ids = Note.commit_note_ids_for_shas(shas, project.id)
          return if note_ids.empty?

          serializer.serialize_relation(relation_schema, batch_ids: note_ids)

          @exported_count += note_ids.size
        end

        # Truncate the relation file the timed-out pagination wrote to.
        def reset_export_file
          path = File.join(shared.export_path, 'tree/project', "#{relation}.ndjson")
          File.truncate(path, 0) if File.exist?(path)
        end

        # rubocop:disable CodeReuse/ActiveRecord -- specific to this service
        def commit_notes_present?
          project.notes.where(noteable_type: 'Commit').exists?
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def log_summary
          Gitlab::Export::Logger.info(
            message: 'commit_notes exported via git repository',
            relation: relation,
            project_id: project.id,
            exported_count: @exported_count
          )
        end

        def log_fallback(error)
          Gitlab::Export::Logger.warn(
            message: 'commit_notes export via notes-table pagination timed out, falling back to git repository walk',
            relation: relation,
            project_id: project.id,
            Labkit::Fields::ERROR_MESSAGE => error.message
          )
        end
      end
    end
  end
end
