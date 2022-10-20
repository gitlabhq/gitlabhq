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

          # TODO: exclude :system, :noteable_type from select after removing override Note#note method
          # https://gitlab.com/gitlab-org/gitlab/-/issues/369923
          def collection
            project.notes.user.select(:id, :note, :system, :noteable_type)
          end
        end
      end
    end
  end
end
