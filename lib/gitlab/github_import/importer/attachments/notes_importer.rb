# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Attachments
        class NotesImporter < ::Gitlab::GithubImport::Importer::Attachments::BaseImporter
          def sidekiq_worker_class
            ::Gitlab::GithubImport::Attachments::ImportNoteWorker
          end

          def collection_method
            :note_attachments
          end

          def object_type
            :note_attachment
          end

          def id_for_already_imported_cache(note)
            note.id
          end

          private

          def collection
            project.notes.id_not_in(already_imported_ids).user.select(:id, :note)
          end
        end
      end
    end
  end
end
