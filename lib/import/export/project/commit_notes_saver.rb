# frozen_string_literal: true

module Import
  module Export
    module Project
      # Replaces the default RelationSaver path for `commit_notes` to avoid
      # `project.commit_notes.in_batches` (which generates
      # `WHERE noteable_type='Commit' ORDER BY id LIMIT N` and times out on
      # large projects). Walks the repo for SHAs, then resolves notes via
      # `commit_id IN (...)` so the query uses `index_notes_on_commit_id`.
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
            next true unless commit_notes_present?

            CommitNotesBatcher.new(project).each_batch { |shas| serialize(shas) }

            log_summary
            true
          end
        rescue StandardError => e
          shared.error(e)
          false
        end

        private

        def serialize(shas)
          note_ids = Note.commit_note_ids_for_shas(shas, project.id)
          return if note_ids.empty?

          serializer.serialize_relation(relation_schema, batch_ids: note_ids)

          @exported_count += note_ids.size
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
      end
    end
  end
end
